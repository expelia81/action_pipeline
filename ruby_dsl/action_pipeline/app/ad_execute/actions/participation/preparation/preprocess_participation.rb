module AdExecute
  module Actions
    # 광고 타입별 전처리(Preprocess) 로직을 실행한다.
    # AdTypeProcessor::ProcessorFactory를 통해 각 타입에 맞는 프로세서를 생성하여
    # 참여 전 필요한 사전 작업(예: 세션 검증, 외부 API 체크 등)을 수행한다.
    #
    # @context_requires [AdParticipateRequest] :request
    # @context_requires [Hash]                :ad_hash
    # @context_requires [Hash]                :ad_type_hash
    # @context_requires [Hash]                :publisher_app_hash
    # @context_requires [String]              :click_key
    class PreprocessParticipation < AdExecute::Action
      requires :request, :ad_hash, :ad_type_hash, :publisher_app_hash, :click_key

      def execute
        request            = context[:request]
        ad_hash            = context[:ad_hash]
        ad_type_hash       = context[:ad_type_hash]
        publisher_app_hash = context[:publisher_app_hash]
        click_key          = context[:click_key]

        processor = AdTypeProcessor::ProcessorFactory.create(ad_type_hash[:code])
        return unless processor.present?

        processor.preprocess_for_participation(
          ad_hash:            ad_hash,
          ad_type_hash:       ad_type_hash,
          uid:                request.uid,
          advertising_id:     request.advertising_id,
          publisher_app_hash: publisher_app_hash,
          client_ip:          request.client_ip,
          placement_id:       request.placement_id,
          request_id:         request.request_id,
          action_id:          request.action_id,
          inventory:          request.inventory,
          is_lat:             request.is_lat,
          os_ver:             request.os_ver,
          tab_slug:           request.tab_slug,
          tag_slug:           request.tag_slug,
          click_key:          click_key
        )
      end
    end
  end
end
