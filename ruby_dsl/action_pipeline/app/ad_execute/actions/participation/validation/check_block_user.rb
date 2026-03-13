module AdExecute
  module Actions
    # 유저 블랙리스트 등록 여부 및 광고별 차단 조건을 확인한다.
    # 차단된 유저인 경우 파이프라인을 중단한다.
    #
    # @context_requires [String]  :uid   유저 식별자
    # @context_requires [Integer] :ad_id 광고 ID
    class CheckBlockUser < AdExecute::Action
      include Modules::AdSettleTypeBlockCacheManager

      requires :request, :ad_hash, :publisher_app_hash

      def execute
        ad_hash            = context[:ad_hash]
        request            = context[:request]
        publisher_app_hash = context[:publisher_app_hash]

        # 캐시 매니저를 통해 차단 여부 확인 (BlockPublisherUserService 의존성 제거)
        if blocked_user?(ad_hash, publisher_app_hash[:publisher_id], request.uid, request.advertising_id)
          raise AdisonErrors::BadRequest.new(Errors::CAMPAIGN_ALREADY_COMPLETE, options: { log_message: 'blocked by block_publisher_user' })
        end
      end

      private

      def blocked_user?(ad_hash, publisher_id, uid, advertising_id)
        return false if ad_hash.blank? || ad_hash[:ad_settle_type_id].blank?

        blocked_ad_settle_types = fetch_blocked_ad_settle_types(publisher_id, uid, advertising_id)
        blocked_ad_settle_types.include?(ad_hash[:ad_settle_type_id].to_s)
      end

      def fetch_blocked_ad_settle_types(publisher_id, uid, advertising_id)
        blocked_ad_settle_types = fetch_blocked_ad_settle_types_from_cache(publisher_id, uid, advertising_id)
        ad_settle_type_ids = (blocked_ad_settle_types[:uid] + blocked_ad_settle_types[:advertising_id])
        ad_settle_type_ids.to_set
      end
    end
  end
end
