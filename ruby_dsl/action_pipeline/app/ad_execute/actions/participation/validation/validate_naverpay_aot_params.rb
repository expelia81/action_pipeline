module AdExecute
  module Actions
    # 네이버페이 AOT(Affiliate Order Tracking) 광고 매체 유효성을 검증한다.
    # 이 액션은 네이버페이 CPA 성과형 광고 파이프라인에서 사용된다.
    class ValidateNaverpayAotParams < AdExecute::Action
      requires :request, :ad_hash

      def execute
        request = context[:request]
        ad_hash = context[:ad_hash]

        aot_source = request.aot_source
        aot_medium = request.aot_medium

        # 네이버페이 AOT 필수 파라미터 누락 체크
        raise AdisonErrors::InvalidParameter.new(options: { log_message: "not exist participate_campaign_params - aot_source" }) unless aot_source.present?
        raise AdisonErrors::InvalidParameter.new(options: { log_message: "not exist participate_campaign_params - aot_medium" }) unless aot_medium.present?

        # 네이버페이 트래킹 매체(aot_medium) 상태 체크
        aot_medium_hash = NaverpayAotMedium.fetch_hash_by_aot_source_and_aot_medium(aot_source, aot_medium)
        if aot_medium_hash.blank?
          raise AdisonErrors::InvalidParameter.new(options: { log_message: "unregistered aot_medium: #{aot_source}/#{aot_medium}" })
        end

        raise AdisonErrors::InvalidParameter.new(Errors::NAVERPAY_AOT_MEDIUM_PAUSED) if NaverpayAotMedium.paused?(aot_medium_hash)
        raise AdisonErrors::InvalidParameter.new(Errors::NAVERPAY_AOT_MEDIUM_TERMINATED) if NaverpayAotMedium.terminated?(aot_medium_hash)
      end
    end
  end
end
