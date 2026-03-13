module AdExecute
  module Actions
    # 광고 캠페인의 디바이스 타겟팅 및 유저 그룹 타겟팅 조건을 검증한다.
    # targeting_type이 설정된 경우 advertising_id 기반으로 허용/차단 캠페인 목록을 조회하고,
    # targeting_user_group이 설정된 경우 유저 그룹 소속 여부를 확인한다.
    # 타겟팅 조건에 해당하지 않으면 NOT_TARGETING_USER_FOR_CAMPAIGN 에러로 파이프라인을 중단한다.
    #
    # @context_requires [Hash]                :ad_hash  광고 정보 해시 (campaign_id, targeting_type 포함)
    # @context_requires [AdParticipateRequest] :request 참여 요청 DTO (advertising_id 사용)
    class ValidateDevice < AdExecute::Action
      include Modules::CampaignTargetCacheManager
      include Modules::TargetingUserGroupCacheManager

      requires :request, :ad_hash, :publisher_app_hash

      def execute
        ad_hash = context[:ad_hash]
        request = context[:request]
        publisher_app_hash = context[:publisher_app_hash]
        advertising_id = request.advertising_id

        # 1. 디바이스/플랫폼별 특수 유효성 검사 (ParticipateService 로직 이관)
        validate_zero_idfa(publisher_app_hash[:platform], request.advertising_id)
        validate_google_ad_id_tracking_limit(publisher_app_hash, advertising_id)
        validate_uid_format_for_cookie_oven(publisher_app_hash, request.uid)

        # 2. 캠페인 타겟팅 및 유저 그룹 타겟팅 검증
        validate_campaign_targeting(ad_hash, advertising_id)
        validate_user_group_targeting(ad_hash[:campaign_id], advertising_id)
      end

      private

      # IDFA 가 0 인 비정상적인 경우 참여제한
      def validate_zero_idfa(platform, idfa)
        if platform == PublisherApp::Platform::IOS && idfa == '00000000-0000-0000-0000-000000000000'
          raise AdisonErrors::BadRequest.new(Errors::NOT_SUPPORT_CLIENT_OS_BETA_VERSION)
        end
      end

      # GAID(광고 ID) 가 설정 되지 않은 경우 참여 제한
      def validate_google_ad_id_tracking_limit(publisher_app_hash, google_ad_id)
        return unless publisher_app_hash[:platform] == PublisherApp::Platform::ANDROID
        return unless google_ad_id.present?

        if google_ad_id == '00000000-0000-0000-0000-000000000000' # GOOGLE_AD_ID_OPT_OUT_STR
          raise AdisonErrors::BadRequest.new(Errors::AOS_NEED_TO_ENABLE_APP_TRACKING, options: { log_message: 'app tracking limit enabled' })
        end
      end

      # IDNO 가 아닌 네이버ID 를 사용하는 구버전 쿠키오븐 앱은 참여 차단
      def validate_uid_format_for_cookie_oven(publisher_app_hash, uid)
        return unless PublisherApp.cookie_oven?(publisher_app_hash[:code])
        unless PublisherGroup.cookie_oven_idno?(uid)
          raise AdisonErrors::BadRequest.new(Errors::NOT_SUPPORT_COOKIE_OVEN_IDNO_SDK_VERSION, options: { log_message: 'uid is not idno format' })
        end
      end

      def validate_campaign_targeting(ad_hash, advertising_id)
        campaign_id = ad_hash[:campaign_id]
        targeting_type = ad_hash[:targeting_type].presence || Campaign.fetch_campaign_hash(campaign_id)[:targeting_type]
        return unless targeting_type.present?

        raise AdisonErrors::BadRequest.new(Errors::NOT_TARGETING_USER_FOR_CAMPAIGN, options: { log_message: 'not existed advertising_id' }) unless advertising_id.present?

        target_and_detarget_campaigns = fetch_target_and_detarget_campaigns_from_cache(advertising_id)
        raise AdisonErrors::BadRequest.new(Errors::NOT_TARGETING_USER_FOR_CAMPAIGN) unless allow_campaign_by_targeting?(campaign_id.to_s, targeting_type, target_and_detarget_campaigns)
      end

      def validate_user_group_targeting(campaign_id, advertising_id)
        campaign_hash = Campaign.fetch_campaign_hash(campaign_id)
        targeted_ids   = campaign_hash[:targeted_targeting_user_group_ids]
        detargeted_ids = campaign_hash[:detargeted_targeting_user_group_ids]
        return if targeted_ids.blank? && detargeted_ids.blank?

        user_group_ids = fetch_targeting_user_group_ids_from_cache(advertising_id)
        raise AdisonErrors::BadRequest.new(Errors::NOT_TARGETING_USER_FOR_CAMPAIGN) unless allowed_targeting_user_group?(targeted_ids, detargeted_ids, user_group_ids)
      end
    end
  end
end
