module AdExecute
  module Actions
    # IDFA 광고추적제한 여부를 검증한다.
    # CampaignService#validate_idfa_tracking_limit 로직을 Action으로 이관하여 Service 의존성을 제거함.
    class ValidateIdfaTracking < AdExecute::Action
      IDFA_TRACKING_LIMIT_MIN_OS_VER = "14.5"
      IDFA_TRACKING_ENABLE_MIN_SDK_VER = "2.0"
      COOKIE_OVEN_IDFA_TRACKING_PASS_MIN_SDK_VER = "2.6"
      COOKIE_OVEN_IDFA_TRACKING_PASS_MAX_SDK_VER = "2.7.99"

      requires :request, :ad_hash, :ad_type_hash, :publisher_app_hash

      def execute
        request            = context[:request]
        ad_hash            = context[:ad_hash]
        ad_type_hash       = context[:ad_type_hash]
        publisher_app_hash = context[:publisher_app_hash]

        is_lat  = request.is_lat
        os_ver  = request.os_ver
        sdk_ver = request.sdk_ver

        # 광고 추적 제한이 없으면 통과
        return unless is_lat == AdisonConstants::AdTrackingLimit::ENABLE

        return unless publisher_app_hash[:platform] == PublisherApp::Platform::IOS

        return if idfa_tracking_pass_sdk_version?(publisher_app_hash[:code], sdk_ver)

        return unless requiring_idfa_ad?(ad_hash, ad_type_hash[:code], os_ver)

        # iOS 버전 14.5 미만은 기존 에러 처리
        if VersionUtil.compare_version(IDFA_TRACKING_LIMIT_MIN_OS_VER, os_ver) == 1
          raise AdisonErrors::BadRequest.new(Errors::NOT_EXIST_ADVERTISING_ID, options: { log_message: 'ad tracking limit enabled' })
        end

        if VersionUtil.compare_version(IDFA_TRACKING_ENABLE_MIN_SDK_VER, sdk_ver) != 1
          raise AdisonErrors::BadRequest.new(Errors::NEED_TO_ENABLE_APP_TRACKING, options: { log_message: 'app tracking limit enabled' })
        end

        # 신규 버전 SDK가 탑재된 매체이면서 구버전 SDK 유저인 경우
        if publisher_app_hash[:supports_ios14] == PublisherApp::SupportsIos14::SUPPORT
          raise AdisonErrors::BadRequest.new(Errors::NEED_APP_UPDATE_FOR_PARTICIPATE, options: { log_message: 'ad tracking limit enabled' })
        end

        # 신규 버전 SDK가 탑재되지 않은 매체 및 기타 예외 케이스 에러 처리
        raise AdisonErrors::BadRequest.new(Errors::NEED_PUBLISHER_SDK_UPDATE, options: { log_message: 'ad tracking limit enabled' })
      end

      private

      def idfa_tracking_pass_sdk_version?(publisher_app_code, sdk_ver)
        return false unless sdk_ver.present?
        return false unless PublisherApp.cookie_oven?(publisher_app_code)

        VersionUtil.parse(sdk_ver) >= VersionUtil.parse(COOKIE_OVEN_IDFA_TRACKING_PASS_MIN_SDK_VER) &&
          VersionUtil.parse(sdk_ver) <= VersionUtil.parse(COOKIE_OVEN_IDFA_TRACKING_PASS_MAX_SDK_VER)
      end

      def requiring_idfa_ad?(ad_hash, ad_type_code, os_ver)
        if VersionUtil.compare_version(IDFA_TRACKING_LIMIT_MIN_OS_VER, os_ver) == 1
          [AdType::Types::CPA_BRIDGE, AdType::Types::CPA_TRACKER].include?(ad_type_code.to_s)
        else
          # iOS버전 14.5 부터는 광고 액션 타입을 기준으로 IDFA 필요 여부를 판단한다.
          Ad.app_action_type?(ad_hash)
        end
      end
    end
  end
end
