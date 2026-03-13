module AdExecute
  module Actions
    # 네이버페이 AOT(Affiliate Order Tracking) 참여 정보를 DB에 저장한다.
    #
    # @context_requires [AdParticipateRequest] :request           참여 요청 DTO (aot_source, aot_medium, aot_sub_params 포함)
    # @context_requires [Hash]                :ad_hash            광고 정보 해시
    # @context_requires [Hash]                :publisher_app_hash 퍼블리셔 앱 정보 해시
    # @context_requires [String]              :click_key          클릭 키
    class CreateNaverpayAotParticipate < AdExecute::Action
      requires :request, :ad_hash, :publisher_app_hash, :click_key

      def execute
        request            = context[:request]
        ad_hash            = context[:ad_hash]
        publisher_app_hash = context[:publisher_app_hash]
        click_key          = context[:click_key]
        now                = Time.now

        info = {
          ad_id:            ad_hash[:id],
          publisher_id:     publisher_app_hash[:publisher_id],
          publisher_app_id: publisher_app_hash[:id],
          aot_source:       request.aot_source,
          aot_medium:       request.aot_medium,
          aot_sub_params:   request.aot_sub_params,
          click_key:        click_key,
          uid:              request.uid,
          advertising_id:   request.advertising_id
        }

        created_at = now.strftime('%Y-%m-%d %H:%M:%S')
        sql = ActiveRecord::Base.sanitize_sql_array([
          'INSERT INTO naverpay_aot_participates (ad_id, publisher_id, publisher_app_id, aot_source, aot_medium, aot_sub_params, click_key, uid, advertising_id, created_at) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          info[:ad_id], info[:publisher_id], info[:publisher_app_id],
          info[:aot_source], info[:aot_medium], info[:aot_sub_params],
          info[:click_key], info[:uid], info[:advertising_id], created_at
        ])

        # 네이버페이 AOT 참여 DB 저장은 트랜잭션 수명 내에서 동기식으로 확실하게 보장
        ActiveRecord::Base.connection_pool.with_connection { |c| c.execute(sql) }
      end
    end
  end
end
