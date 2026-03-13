module AdExecute
  module Actions
    # NPCB(네이버페이 쿠폰 보장형) 광고의 고유 참여 토큰을 생성한다.
    # 생성된 토큰은 이후 GenerateLandingUrl에서 URL 매크로 치환에 사용된다.
    # NPCB 타입이 아닌 경우 nil이 저장된다.
    #
    # @context_requires [Hash]   :ad_type_hash              광고 타입 정보 해시 (code로 NPCB 여부 판별)
    #
    # @context_provides [String, nil] :generated_npcb_p_token 생성된 NPCB 참여 토큰 (비NPCB 타입이면 nil)
    class GenerateNpcbToken < AdExecute::Action
      requires :ad_type_hash
      provides :generated_npcb_p_token

      def execute
        # NPCB 보장성 전용 파이프라인에서만 실행되므로 별도의 타입 필터링 없이 즉시 발급한다.
        context[:generated_npcb_p_token] = SecureRandom.urlsafe_base64(16)
      end
    end
  end
end
