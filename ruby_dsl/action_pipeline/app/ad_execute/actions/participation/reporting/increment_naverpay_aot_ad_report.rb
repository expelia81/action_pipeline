module AdExecute
  module Actions
    # NaverpayAOT 광고 실적(NaverpayAotAdReport)의 참여 카운터를 Redis에서 증가시킨다.
    # NaverpayAOT 대상 광고 타입이 아닌 경우 건너뛴다.
    # aot_source 또는 aot_medium이 누락된 경우 warn 로그를 남기고 집계를 생략한다.
    #
    # @note with_transaction 밖, with_lock 안에서 실행해야 한다 (Redis는 DB 트랜잭션 롤백 대상 아님)
    # @note aot_source/aot_medium 누락 시 Redis 집계만 생략되나, CreateParticipateRecord에서
    #   이미 DB에 null 값으로 INSERT된 상태이므로 데이터 싱크 불일치가 발생할 수 있다. (추후 설계 보완 필요)
    #
    # @context_requires [Hash]                :ad_hash  광고 정보 해시 (ad_type_id로 AOT 대상 여부 판별)
    # @context_requires [AdParticipateRequest] :request 참여 요청 DTO (aot_source, aot_medium 포함 가능)
    class IncrementNaverpayAotAdReport < AdExecute::Action
      requires :ad_hash, :request

      def execute
        ad_hash = context[:ad_hash]
        return unless AdType.naverpay_aot_ad_report_target_ad_type?(ad_hash[:ad_type_id])

        aot_source = context[:request].aot_source
        aot_medium = context[:request].aot_medium

        if aot_source.blank? || aot_medium.blank?
          log_warn 'aot_source/aot_medium 누락으로 집계 생략',
                   { ad_id: ad_hash[:id], aot_source: aot_source, aot_medium: aot_medium }
          return
        end

        ad_id_array = Ad.ad_id_array(ad_hash)
        NaverpayAotAdReport.increment_participate(ad_id_array, aot_source, aot_medium, Time.now)
      end
    end
  end
end
