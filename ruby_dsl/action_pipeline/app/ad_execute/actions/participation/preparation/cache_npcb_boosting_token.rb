module AdExecute
  module Actions
    # 네이버페이 포인트보장 CPS BOOSTING 광고의 참여 토큰을 캐시에 저장한다.
    # (다른 유저가 이 광고를 클릭했을 때 부스팅 보상을 받기 위한 참조 토큰 용도)
    #
    # @context_requires [Hash]   :ad_hash                광고 정보 해시
    # @context_requires [String] :click_key              클릭 키
    # @context_requires [String] :uid                    사용자 식별자
    # @context_requires [String] :advertising_id        ADID
    # @context_requires [Hash]   :publisher_app_hash     퍼블리셔 앱 정보
    # @context_requires [String] :generated_npcb_p_token 생성된 포인트보장 토큰
    class CacheNpcbBoostingToken < AdExecute::Action
      requires :ad_hash, :click_key, :request, :publisher_app_hash, :generated_npcb_p_token, :participate_info

      def execute
        ad_hash                = context[:ad_hash]
        click_key              = context[:click_key]
        request                = context[:request]
        publisher_app_hash     = context[:publisher_app_hash]
        generated_npcb_p_token = context[:generated_npcb_p_token]
        now                    = Time.now
        
        return if generated_npcb_p_token.blank?

        # CreateParticipateRecord에서 생성된 공통 참여 정보를 기반으로 부스팅 정보 구성
        boosting_participation_info = context[:participate_info].merge(
          npcb_p_token:    generated_npcb_p_token,
          participated_at: now.strftime('%Y-%m-%d %H:%M:%S')
        )

        participate_expired_at = ad_hash[:participate_expired_at]
        
        cache_key = format('npcb_p_token_%<token>s', token: generated_npcb_p_token)
        cache_options = { namespace: 'api', expires_in: 1.day, raw: false }
        cache_options[:expires_in] = participate_expired_at.to_i.days if participate_expired_at.to_i.positive?
        
        Rails.cache.write(cache_key, boosting_participation_info, cache_options)
      end
    end
  end
end
