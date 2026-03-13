module AdExecute
  module Actions
    # Sidekiq을 통해 포스트백 워커(PostbackWorker)를 비동기로 실행 요청한다.
    # 포스트백은 즉시 처리되지 않고 큐에 적재되어 별도 워커가 처리한다.
    # CPA 계열 광고는 즉시 포스트백이 없으므로 해당 Executor에서는 이 Action을 포함하지 않는다.
    #
    # @context_requires [AdParticipateRequest] :request   참여 요청 DTO (uid 포함)
    # @context_requires [Hash]                :ad_hash    광고 정보 해시 (id, token 포함)
    # @context_requires [String]              :click_key  클릭 키
    class RequestPostback < AdExecute::Action
      requires :request, :ad_hash, :click_key, :ad_type_hash, :publisher_app_hash
      provides :complete_delay_time

      def execute
        ad_hash            = context[:ad_hash]
        ad_type_hash       = context[:ad_type_hash]
        click_key          = context[:click_key]
        request            = context[:request]
        publisher_app_hash = context[:publisher_app_hash]

        # 즉시 포스트백 허용 타입인지 재검증 (Executor가 배치했으므로 보수적 확인)
        return unless AdType.cpc_type_code?(ad_type_hash[:code]) || AdType.cpm_type_code?(ad_type_hash[:code])

        # 중복 포스트백 방지 캐시 확인
        ad_token = ad_hash[:token]
        if postback_requested?(request.uid, ad_token)
          Rails.logger.info("already postback requested", { uid: request.uid, ad_token: ad_token, click_key: click_key })
          return
        end

        # SDK 지연적립 설정 확인 (ParticipateService#request_postback_for_sdk_api 로직 이관)
        ad_extra_vars = Ad.extra_infos(ad_hash)
        complete_delay_time = ad_extra_vars[:complete_delay_time]
        sdk_ver = request.sdk_ver
        
        if complete_delay_by_sdk?(sdk_ver, complete_delay_time, publisher_app_hash)
          log_info "SDK 지연적립 대상이므로 포스트백 요청 스킵: #{ad_hash[:id]}", { sdk_ver: sdk_ver, delay: complete_delay_time }
          context[:complete_delay_time] = complete_delay_time
          return
        end

        write_postback_request(request.uid, ad_token)
        PostbackWorker.perform_async(ad_hash[:id], click_key, request.uid, ad_hash[:token])
      end

      private

      def complete_delay_by_sdk?(sdk_ver, complete_delay_time, publisher_app_hash)
        return false unless complete_delay_time.present?
        return false if PublisherApp.web_platform?(publisher_app_hash[:platform]) # 웹 매체는 SDK 지연적립 미지원
        return false if PublisherApp.cookie_oven?(publisher_app_hash[:code]) && VersionUtil.parse(sdk_ver) < VersionUtil.parse(ParticipateService::CompleteDelaySupportSdkVersion::COOKIE_OVEN)
        return false if VersionUtil.parse(sdk_ver) < VersionUtil.parse(ParticipateService::CompleteDelaySupportSdkVersion::DEFAULT)

        true
      end

      def postback_requested?(uid, ad_token)
        key, options = cache_info_for_postback_request(uid, ad_token)
        Rails.cache.read(key, options)
      end

      def write_postback_request(uid, ad_token)
        key, options = cache_info_for_postback_request(uid, ad_token)
        Rails.cache.write(key, true, options)
      end

      def cache_info_for_postback_request(uid, ad_token)
        key = format(ParticipateService::Cache::POSTBACK_PARTICIPATING_REQUEST[:key], uid: uid, ad_token: ad_token)
        options = ParticipateService::Cache::POSTBACK_PARTICIPATING_REQUEST[:options]
        [key, options]
      end
    end
  end
end
