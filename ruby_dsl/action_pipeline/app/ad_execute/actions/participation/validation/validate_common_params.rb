module AdExecute
  module Actions
    # 공통 참여 파라미터(NPCB 토큰, AOT 소스 등)의 유효성 및 조합 가능 여부를 검증한다.
    # ParticipateService#validate_ad_type_participate_campaign_params 로직을 Action으로 통합함.
    class ValidateCommonParams < AdExecute::Action
      requires :request, :ad_hash

      def execute
        request = context[:request]
        ad_hash = context[:ad_hash]

        # 1. NPCB 부스팅 토큰 체크 (지원되지 않는 타입인 경우 오류)
        if request.referenced_npcb_p_token.present?
          unless AdType.cps_boostable_ad_type?(ad_hash[:ad_type_id])
            raise AdisonErrors::InvalidParameter.new(options: { log_message: "not allowed participate_campaign_params - referenced_npcb_p_token" })
          end
        end

        # 2. Naverpay AOT 파라미터 체크 (지원되지 않는 타입인 경우 오류)
        if request.aot_source.present? || request.aot_medium.present?
          unless AdType.naverpay_aot_ad_report_target_ad_type?(ad_hash[:ad_type_id])
            raise AdisonErrors::InvalidParameter.new(options: { log_message: "not allowed participate_campaign_params - aot" })
          end
        end
      end
    end
  end
end
