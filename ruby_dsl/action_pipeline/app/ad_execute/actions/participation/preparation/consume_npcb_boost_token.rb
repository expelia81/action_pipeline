module AdExecute
  module Actions
    # CPS 부스팅용 참조 토큰(referenced_npcb_p_token)을 읽고 유효성을 검증한다.
    # 토큰이 유효하면 해당 부스팅 정보를 참여 정보에 결합한다.
    #
    # @context_requires [AdParticipateRequest] :request  참여 요청 DTO (referenced_npcb_p_token 포함)
    # @context_requires [Hash]                :ad_hash   광고 정보 해시
    class ConsumeNpcbBoostToken < AdExecute::Action
      requires :request, :ad_hash
      provides :referenced_npcb_p_token

      def execute
        request = context[:request]
        ad_hash = context[:ad_hash]
        referenced_npcb_p_token = request.referenced_npcb_p_token

        return unless referenced_npcb_p_token.present?

        # 참여 서비스의 private 메소드 로직을 직접 구현 (또는 믹스인 사용 가능하나 단순 로직이므로 인라인)
        # ParticipateService#read_npcb_p_cache 로직
        cache_key = format('npcb_p_token_%<token>s', token: referenced_npcb_p_token)
        cache_options = { namespace: 'api', expires_in: 1.day, raw: false }
        
        npcb_p_cache = Rails.cache.read(cache_key, cache_options)
        
        if npcb_p_cache.blank?
          Rails.logger.force_info("npcb_p_cache not exist", { ad_id: ad_hash[:id], uid: request.uid }, { npcb_p_info: { npcb_p_token: referenced_npcb_p_token }})
          return
        end

        # 보상 부인 방지 및 정합성 로그
        npcb_ad_hash = Ad.fetch_ad_hash(npcb_p_cache[:ad_id])
        Rails.logger.force_info("participated with npcb_p_token", { ad_id: ad_hash[:id], ad_name: ad_hash[:name], uid: request.uid }, { npcb_p_info: npcb_p_cache.merge(ad_name: npcb_ad_hash[:name]) })
        
        # 레코드 생성 시 사용되도록 컨텍스트에 기록
        context[:referenced_npcb_p_token] = referenced_npcb_p_token
      end
    end
  end
end
