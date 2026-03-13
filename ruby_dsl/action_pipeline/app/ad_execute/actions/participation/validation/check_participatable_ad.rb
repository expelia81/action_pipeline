module AdExecute
  module Actions
    # 광고의 참여 가능 여부를 종합적으로 검증한다.
    # 직접 참여 허용 여부, 광고 타입 활성화, 광고 ON/OFF, 참여 기간, 퍼블리셔앱 상태,
    # 노출 시간대(target_time), 일별/시간별/총량 액션 CAP, CPM 노출 CAP, 예산 CAP을 순서대로 확인한다.
    #
    # @context_requires [AdParticipateRequest] :request           참여 요청 DTO (from 필드로 직접 참여 여부 판별)
    # @context_requires [Hash]                :ad_hash            광고 정보 해시
    # @context_requires [Hash]                :ad_type_hash       광고 타입 정보 해시
    # @context_requires [Hash]                :publisher_app_hash 퍼블리셔 앱 정보 해시 (status 확인)
    class CheckParticipatableAd < AdExecute::Action
      include Modules::CapacityManager

      requires :request, :ad_hash, :ad_type_hash, :publisher_app_hash

      def execute
        request          = context[:request]
        ad_hash          = context[:ad_hash]
        ad_type_hash     = context[:ad_type_hash]
        publisher_app_hash = context[:publisher_app_hash]

        from = request.from
        raise AdisonErrors::BadRequest.new(Errors::DIRECT_PARTICIPATION_DISALLOWED) if from == AdisonConstants::AdParticipateFrom::DIRECT_PARTICIPATION && !Ad.direct_participation_allowed?(ad_hash)

        raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED, options: { log_message: 'ad type disabled' }) if AdType.disabled_type_code?(ad_type_hash[:code]) || AdType.unable_participation_type_codes?(ad_type_hash[:code])
        raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED, options: { log_message: 'ad off' }) unless Ad.enable?(ad_hash)
        raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED, options: { log_message: 'ad end' }) unless Ad.participation_period?(ad_hash)
        raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED, options: { log_message: 'publisher app closed' }) if publisher_app_hash[:status] == PublisherApp::Status::CLOSED

        extra_filters_hash = AdisonCommonUtil.json_to_hash(ad_hash[:extra_filters])
        raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED, options: { log_message: 'ad not target_time' }) unless Ad.target_time?(extra_filters_hash[:target_times], ad_hash[:show_status])



        check_participatable_cap(ad_hash, ad_type_hash: ad_type_hash)
      end

      private

      def check_participatable_cap(ad_hash, ad_type_hash: nil)
        result_hash, exceed_total_action_cap, exceed_current_action_cap = check_action_cap(ad_hash)
        check_info    = result_hash[:check_info]
        exceed_reason = check_info[:exceed_reason]

        raise AdisonErrors::BadRequest.new(Errors::EXCEED_DAILY_CAPACITY, options: { log_event_info: check_info }) if exceed_current_action_cap && exceed_reason == AdisonConstants::ExceedCapReason::DAY
        raise AdisonErrors::BadRequest.new(Errors::EXCEED_TIME_CAPACITY,  options: { log_event_info: check_info }) if exceed_current_action_cap && exceed_reason == AdisonConstants::ExceedCapReason::TIME
        raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED,           options: { log_event_info: check_info }) if exceed_total_action_cap

        ad_type_hash ||= AdType.fetch_ad_type_hash(ad_hash[:ad_type_id])
        if AdType.cpm_type_code?(ad_type_hash[:code])
          result_hash_imp, exceed_total_imp_cap, exceed_current_imp_cap = check_impression_cap(ad_hash)
          check_info = result_hash_imp[:check_info]
          raise AdisonErrors::BadRequest.new(Errors::EXCEED_DAILY_CAPACITY, options: { log_event_info: check_info }) if exceed_current_imp_cap
          raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED,           options: { log_event_info: check_info }) if exceed_total_imp_cap
        end

        return unless Ad.budget_cap_enabled?(ad_hash)

        result_hash_budget, exceed_total_budget_cap, exceed_current_budget_cap = check_budget_cap(ad_hash)
        check_info = result_hash_budget[:check_info]
        raise AdisonErrors::BadRequest.new(Errors::EXCEED_DAILY_CAPACITY, options: { log_event_info: check_info }) if exceed_current_budget_cap
        raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED,           options: { log_event_info: check_info }) if exceed_total_budget_cap
      end
    end
  end
end
