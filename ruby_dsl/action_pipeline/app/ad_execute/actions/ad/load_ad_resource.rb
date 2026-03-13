module AdExecute
  module Actions
    # request의 ad_id를 기반으로 광고·광고타입·퍼블리셔앱 리소스를 로드하여 컨텍스트에 저장한다.
    # ad_hash가 존재하지 않으면 NOT_FOUND_AD 에러로 파이프라인을 중단한다.
    #
    # @context_requires [AdParticipateRequest] :request 참여 요청 DTO (ad_id, publisher_app_id 포함)
    #
    # @context_provides [Hash] :ad_hash         광고 정보 해시 (Ad.fetch_ad_hash 결과)
    # @context_provides [Hash] :ad_type_hash    광고 타입 정보 해시 (AdType.fetch_ad_type_hash 결과)
    # @context_provides [Hash] :publisher_app_hash 퍼블리셔 앱 정보 해시
    class LoadAdResource < AdExecute::Action
      requires :request
      provides :ad_hash, :ad_type_hash, :publisher_app_hash, :membership_id

      def execute
        request = context[:request]
        ad_id = request.ad_id

        ad_hash = Ad.fetch_ad_hash(ad_id)
        raise AdisonErrors::BadRequest.new(Errors::NOT_FOUND_AD) if ad_hash.nil? || ad_hash.empty?

        context[:ad_hash] = ad_hash
        context[:ad_type_hash] = AdType.fetch_ad_type_hash(ad_hash[:ad_type_id])

        publisher_app_hash = request.publisher_app_hash
        publisher_app_hash = PublisherApp.fetch_hash_by_id(request.publisher_app_id) if publisher_app_hash.blank? && request.publisher_app_id.present?
        raise AdisonErrors::BadRequest.new(Errors::INVALID_PARAMETER, options: { log_message: 'publisher_app not found' }) if publisher_app_hash.blank?

        context[:publisher_app_hash] = publisher_app_hash
        context[:membership_id] = publisher_app_hash[:membership_id]
      end
    end
  end
end
