module AdExecute
  module Actions
    # 퍼블리셔 그룹의 외부 클라이언트(PublisherGroupClient)를 통해 캠페인 참여 가능 여부를 확인한다.
    # campaign_key가 없거나 CPC 타입인 경우 검사를 건너뛴다.
    # 퍼블리셔 측에서 이미 참여한 캠페인이면 PUBLISHER_CAMPAIGN_ALREADY_COMPLETE 에러를 발생시킨다.
    #
    # @context_requires [AdParticipateRequest] :request           참여 요청 DTO (uid, advertising_id 포함)
    # @context_requires [Hash]                :ad_hash            광고 정보 해시 (campaign_key 포함)
    # @context_requires [Hash]                :ad_type_hash       광고 타입 정보 해시 (CPC 여부 판별)
    # @context_requires [Hash]                :publisher_app_hash 퍼블리셔 앱 정보 해시 (publisher_id 포함)
    class CheckPublisherStatus < AdExecute::Action
      requires :request, :ad_hash, :ad_type_hash, :publisher_app_hash

      def execute
        ad_hash          = context[:ad_hash]
        ad_type_hash     = context[:ad_type_hash]
        publisher_app_hash = context[:publisher_app_hash]
        request          = context[:request]

        campaign_key = ad_hash[:campaign_key]
        return if campaign_key.blank?
        return if AdType.cpc_type_code?(ad_type_hash[:code])

        publisher_hash       = Publisher.fetch_hash_by_id(publisher_app_hash[:publisher_id])
        publisher_group_hash = PublisherGroup.fetch_hash_by_id(publisher_hash[:publisher_group_id])
        client               = PublisherGroupClient::ClientFactory.create(publisher_group_hash)

        participate_result = client.participate_campaign(
          request.uid, ad_hash[:id], campaign_key,
          publisher_app_hash[:id], publisher_app_hash[:code], request.advertising_id
        )

        return if participate_result[:result]

        case participate_result[:result_code]
        when PublisherGroupClient::AbstractClient::ResultCode::DUPLICATED
          raise AdisonErrors::BadRequest.new(Errors::PUBLISHER_CAMPAIGN_ALREADY_COMPLETE)
        else
          raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED)
        end
      end
    end
  end
end
