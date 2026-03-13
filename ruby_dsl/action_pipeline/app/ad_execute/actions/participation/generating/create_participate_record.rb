module AdExecute
  module Actions
    # 참여 레코드를 DB에 저장하고 Redis 캐시에 기록한다.
    # NaverpayAOT 대상 광고 타입인 경우 naverpay_aot_participates 테이블에도 함께 저장한다.
    # CPA 쿠폰 타입이면 v1/v2 양방향 캐시 키로 저장한다.
    # DB INSERT 실패 시 DbInsertRetryService로 재시도를 예약한다.
    #
    # @note with_transaction 블록 내부에서 실행되어 트랜잭션 원자성을 보장한다.
    #
    # @context_requires [AdParticipateRequest] :request           참여 요청 DTO (uid, advertising_id, aot_* 파라미터 포함 가능)
    # @context_requires [Hash]                :ad_hash            광고 정보 해시
    # @context_requires [Hash]                :publisher_app_hash 퍼블리셔 앱 정보 해시
    # @context_requires [String]              :click_key          클릭 키
    class CreateParticipateRecord < AdExecute::Action
      requires :request, :ad_hash, :publisher_app_hash, :click_key
      provides :participate_info
      optional :referenced_npcb_p_token, :generated_npcb_p_token

      def execute
        request          = context[:request]
        ad_hash          = context[:ad_hash]
        publisher_app_hash = context[:publisher_app_hash]
        click_key        = context[:click_key]
        now              = Time.now

        participate_info = build_participate_info(request, ad_hash, publisher_app_hash, click_key)
        
        # AOT 정보 주입 (레포트 및 포스트백 참조용 캐시)
        participate_info[:aot_source]     = request.aot_source
        participate_info[:aot_medium]     = request.aot_medium
        participate_info[:aot_sub_params] = request.aot_sub_params

        # NPCB 부스팅 토큰이 있다면 참여 정보에 주입 (ConsumeNpcbBoostToken 액션에서 제공)
        participate_info[:npcb_p_token] = context[:referenced_npcb_p_token] if context[:referenced_npcb_p_token].present?
        
        # 생성된 NPCB 토큰이 있다면 주입 (GenerateNpcbToken 액션에서 제공)
        participate_info[:generated_npcb_p_token] = context[:generated_npcb_p_token] if context[:generated_npcb_p_token].present?

        # 후속 Action(CacheOfferwallCoupon 등)에서 재사용할 수 있도록 컨텍스트에 저장
        context[:participate_info] = participate_info

        # 참여 DB 저장은 트랜잭션 안전성을 위해 동기적으로 처리 (Executor 레벨 트랜잭션 원자성 확보)
        create_participate(participate_info, now)

        write_to_cache(participate_info, ad_hash, click_key)
      end

      private

      def build_participate_info(request, ad_hash, publisher_app_hash, click_key)
        {
          click_key:           click_key,
          ad_id:               ad_hash[:id],
          publisher_id:        publisher_app_hash[:publisher_id],
          membership_id:       publisher_app_hash[:membership_id],
          publisher_app_id:    publisher_app_hash[:id],
          publisher_app_token: publisher_app_hash[:token],
          uid:                 request.uid,
          advertising_id:      request.advertising_id,
          placement_id:        request.placement_id,
          request_id:          request.request_id,
          action_id:           request.action_id,
          inventory:           request.inventory,
          tab_slug:            request.tab_slug,
          tag_slug:            request.tag_slug,
          participate_expired_at: ad_hash[:participate_expired_at]
        }
      end

      def write_to_cache(participate_info, ad_hash, click_key)
        participate_expired_at = ad_hash[:participate_expired_at]

        key, options = cache_key_v2(click_key)
        options = options.merge(expires_in: participate_expired_at.to_i.days) if participate_expired_at.to_i.positive?
        Rails.cache.write(key, participate_info, options)
      end

      def cache_key_v2(click_key)
        key     = format('participate_start_v2_%<click_key>s', click_key: click_key)
        options = { namespace: 'api', expires_in: 1.day, raw: false }
        [key, options]
      end

      def create_participate(info, now)
        created_at = now.strftime('%Y-%m-%d %H:%M:%S')
        sql = ActiveRecord::Base.sanitize_sql_array([
          'INSERT INTO participates (click_key, ad_id, publisher_id, publisher_app_id, uid, advertising_id, created_at) VALUES(?, ?, ?, ?, ?, ?, ?)',
          info[:click_key], info[:ad_id], info[:publisher_id], info[:publisher_app_id], info[:uid], info[:advertising_id], created_at
        ])
        ActiveRecord::Base.connection_pool.with_connection { |c| c.execute(sql) }
      rescue StandardError => e
        Rails.logger.error("create_participate failed: #{e.message}", info)
        DbInsertRetryService.perform_in(Participate.table_name, sql, info.merge(created_at: created_at))
        raise e # 트랜잭션 롤백을 위해 예외를 다시 던짐
      end
    end
  end
end
