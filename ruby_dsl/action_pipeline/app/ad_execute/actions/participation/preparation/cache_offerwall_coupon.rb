module AdExecute
  module Actions
    # 오퍼월 쿠폰 타입 광고인 경우, UID와 광고 토큰 기반의 V1 캐시를 추가로 생성한다.
    # 이는 구버전 API(v1)와의 하위 호환성 또는 쿠폰 발급 조회를 위해 필요하다.
    #
    # @context_requires [Hash]   :ad_hash   광고 정보 해시
    # @context_requires [String] :click_key 클릭 키
    # @context_requires [AdParticipateRequest] :request 참여 요청 정보
    class CacheOfferwallCoupon < AdExecute::Action
      requires :ad_hash, :click_key, :request, :participate_info

      def execute
        ad_hash   = context[:ad_hash]
        click_key = context[:click_key]
        request   = context[:request]
        
        # CreateParticipateRecord에서 생성된 공통 참여 정보를 사용
        participate_info = context[:participate_info]
        
        # participate_start_%{uid}_%{ad_token} 형태의 V1 캐시 키 사용
        key = format('participate_start_%<uid>s_%<ad_token>s', uid: request.uid, ad_token: ad_hash[:token])
        options = { namespace: 'api', expires_in: 1.day, raw: false }
        
        participate_expired_at = ad_hash[:participate_expired_at]
        options[:expires_in] = participate_expired_at.to_i.days if participate_expired_at.to_i.positive?

        Rails.cache.write(key, participate_info, options)
      end
    end
  end
end
