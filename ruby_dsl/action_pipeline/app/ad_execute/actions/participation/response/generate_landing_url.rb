module AdExecute
  module Actions
    # 광고 랜딩 URL을 생성한다.
    # ParticipateAdNetwork에서 이미 landing_url이 설정된 경우 건너뛴다.
    # 트래커(Tracker)가 설정된 경우 트래커 클릭 URL로 변환하고,
    # URL 매크로(click_key, advertising_id, publisher 코드 등)를 치환한다.
    # 플랫폼에 따라 URL 인코딩을 적용한다.
    #
    # @context_requires [AdParticipateRequest] :request           참여 요청 DTO (uid, advertising_id 포함)
    # @context_requires [Hash]                :ad_hash            광고 정보 해시 (tracker_id, reward 등 포함)
    # @context_requires [Hash]                :publisher_app_hash 퍼블리셔 앱 정보 해시 (platform, membership_id 등 포함)
    # @context_requires [String]              :click_key          클릭 키
    #
    # @context_provides [String] :landing_url 최종 랜딩 URL (매크로 치환 및 인코딩 완료)
    class GenerateLandingUrl < AdExecute::Action
      include Modules::LandingUrlMacroManager
      include Modules::RewardTypeCacheManager

      requires :request, :ad_hash, :publisher_app_hash, :click_key
      provides :landing_url
      optional :generated_npcb_p_token

      def execute
        return if context[:landing_url].present?

        request          = context[:request]
        ad_hash          = context[:ad_hash]
        publisher_app_hash = context[:publisher_app_hash]
        click_key        = context[:click_key]

        publisher_hash = Publisher.fetch_hash_by_id(publisher_app_hash[:publisher_id])
        uri            = Ad.ad_uri(ad_hash, publisher_app_hash[:platform])

        landing_url = build_landing_url(
          ad_hash, publisher_hash, publisher_app_hash,
          uri, click_key, request
        )

        context[:landing_url] = landing_url
      end

      private

      def build_landing_url(ad_hash, publisher_hash, publisher_app_hash, uri, click_key, request)
        tracker_id = ad_hash[:tracker_id].to_i

        if tracker_id != 0
          tracker_hash = Tracker.fetch_hash_by_id(tracker_id)
          url = Tracker.click_url(uri, tracker_hash[:click_params])
          advertising_id = AdvertisingIdUtil.web_advertising_id_format?(request.advertising_id) ? nil : request.advertising_id
        else
          url = uri
          advertising_id = request.advertising_id
        end

        reward              = ad_hash[:reward] if Ad.fixed_reward_grant_type?(ad_hash)
        campaign_id         = ad_hash[:campaign_id].presence
        reward_type_app_unit = fetch_reward_types_by_publisher_app_id(publisher_app_hash[:id])&.first&.dig(:unit)
        neptune_zone_code   = publisher_app_hash.dig(:extra_vars, :neptune_zone_code)

        # 네이버쇼핑 어필리에이트 광고 랜딩 URL 값
        aot_source = request.aot_source
        aot_medium = request.aot_medium
        navershopping_affiliate_landing_query_params = nil
        if aot_source.present? && aot_medium.present?
          navershopping_affiliate_landing_query_params = resolve_navershopping_affiliate_landing_query_params_for_macro(aot_source, aot_medium)
        end

        # 나이비 광고주 전용 랜딩 URL 값
        naivy_reward_point_landing_query_params = nil
        if url.include?(LandingUrlMacro::NAIVY_REWARD_POINT_LANDING_QUERY_PARAMS)
          naivy_reward_point_landing_query_params = resolve_naivy_landing_query_params_for_macro(ad_hash, publisher_hash[:code])
        end

        # NPCB 생성 토큰 (NpcbParticipateExecutor에서 생성하여 컨텍스트에 존재)
        generated_npcb_p_token = context[:generated_npcb_p_token]

        url = replace_macro(
          url, click_key, advertising_id,
          publisher_app_hash[:platform],
          publisher_hash[:id], publisher_hash[:code],
          publisher_app_hash[:code], publisher_app_hash[:membership_id],
          request.uid, ad_hash[:id], ad_hash[:start_at],
          reward: reward,
          campaign_id: campaign_id,
          generated_npcb_p_token: generated_npcb_p_token,
          neptune_zone_code: neptune_zone_code,
          navershopping_affiliate_landing_query_params: navershopping_affiliate_landing_query_params,
          naivy_reward_point_landing_query_params: naivy_reward_point_landing_query_params,
          reward_type_app_unit: reward_type_app_unit
        )

        encoding_uri(url, publisher_app_hash[:platform])
      rescue URI::InvalidURIError => e
        Rails.logger.error('invalid landing_url', { ad_id: ad_hash[:id], click_key: click_key }, { error_message: e.message })
        raise e
      end

      def resolve_navershopping_affiliate_landing_query_params_for_macro(aot_source, aot_medium)
        aot_medium_hash = NaverpayAotMedium.fetch_hash_by_aot_source_and_aot_medium(aot_source, aot_medium)
        NaverpayAotMedium.navershopping_affiliate_landing_query_params(aot_medium_hash)
      end

      def resolve_naivy_landing_query_params_for_macro(ad_hash, publisher_code)
        return unless ad_hash.present?
        return unless Ad.ratio_based_reward_grant_type?(ad_hash)
        return unless ad_hash[:cost_rs_ratio].present?

        cost_by_6 = (ParticipateService::NaivyAmountForLandingUrlMacro::AMOUNT_6 * ad_hash[:cost_rs_ratio]).to_i
        cost_by_12 = (ParticipateService::NaivyAmountForLandingUrlMacro::AMOUNT_12 * ad_hash[:cost_rs_ratio]).to_i

        publisher_hash = Publisher.fetch_hash_by_code(publisher_code)
        publisher_group_ad_settle_type_hash = PublisherGroupAdSettleType.fetch_hash_by_ad_info(publisher_hash[:publisher_group_id], ad_hash[:ad_settle_type_id])
        reward_by_amount_6 = PublisherGroupAdSettleType.calculate_reward_from_hash(publisher_group_ad_settle_type_hash, cost_by_6)
        reward_by_amount_12 = PublisherGroupAdSettleType.calculate_reward_from_hash(publisher_group_ad_settle_type_hash, cost_by_12)

        # 계산 리워드가 0이 되는 매체에는 나이비 광고를 셋팅하지 않을 예정이지만, 휴먼미스를 대비하여 warn 로깅
        if reward_by_amount_6.zero? || reward_by_amount_12.zero?
          additional_infos = { cost_by_6: cost_by_6, cost_by_12: cost_by_12, reward_by_amount_6: reward_by_amount_6, reward_by_amount_12: reward_by_amount_12 }
          Rails.logger.warn("resolve_naivy_landing_query_params_for_macro calculated zero", { ad_id: ad_hash[:id], publisher_code: publisher_code }, additional_infos)
        end

        "userRewardPoint1=#{reward_by_amount_6}&userRewardPoint2=#{reward_by_amount_12}"
      end
    end
  end
end
