module AdExecute
  module Actions
    # 사용자가 해당 캠페인을 이미 완료했는지 확인한다.
    # (PostbackService의 check_completed 로직을 활용)
    #
    # @context_requires [String]  :uid
    # @context_requires [String]  :advertising_id
    # @context_requires [Integer] :membership_id
    # @context_requires [Hash]    :ad_hash
    class CheckAlreadyCompleted < AdExecute::Action
      include Modules::CampaignCompleteCacheManager
      include Modules::DelayCampaignCompleteCacheManager

      requires :uid, :advertising_id, :membership_id, :ad_hash

      def execute
        uid            = context[:uid]
        advertising_id = context[:advertising_id]
        membership_id  = context[:membership_id]
        ad_hash        = context[:ad_hash]
        campaign_id    = ad_hash[:campaign_id]

        # 캐시 매니저를 통해 완료 여부 확인 (PostbackService 의존성 제거)
        completed_campaigns = fetch_completed_campaigns_from_cache(uid, advertising_id, membership_id)
        if completed?(campaign_id, completed_campaigns)
          log_info "이미 완료된 캠페인 참여 시도: campaign_id=#{campaign_id}"
          raise AdisonErrors::BadRequest.new(Errors::CAMPAIGN_ALREADY_COMPLETE)
        end

        if Ad.delay_action?(ad_hash)
          delay_completed_campaigns = read_delay_completed_campaigns_from_cache(uid, advertising_id, membership_id)
          if delay_completed?(campaign_id, delay_completed_campaigns)
            raise AdisonErrors::BadRequest.new(Errors::CAMPAIGN_ALREADY_EXPECT_COMPLETE)
          end
        end
      end

      private

      def completed?(campaign_id, completed_campaigns)
        completed_by_uid = completed_campaigns[:uid][campaign_id.to_s].to_i
        completed_by_advertising_id = completed_campaigns[:advertising_id][campaign_id.to_s].to_i
        completed_by_uid + completed_by_advertising_id > 0
      end

      def delay_completed?(campaign_id, delay_completed_campaigns)
        delay_completed_by_uid = delay_completed_campaigns[:uid][campaign_id.to_s].to_i
        delay_completed_by_advertising_id = delay_completed_campaigns[:advertising_id][campaign_id.to_s].to_i
        delay_completed_by_uid + delay_completed_by_advertising_id > 0
      end
    end
  end
end
