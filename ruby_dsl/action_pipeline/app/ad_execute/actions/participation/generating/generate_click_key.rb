module AdExecute
  module Actions
    # 참여 요청 정보를 기반으로 클릭키(click_key)를 생성하여 컨텍스트에 기록한다.
    #
    # @context_requires [AdParticipateRequest] :request  참여 요청 DTO (uid 포함)
    # @context_requires [Hash]                :ad_hash  광고 정보 해시 (token 포함)
    #
    # @context_provides [String] :click_key 인코딩된 클릭 키
    class GenerateClickKey < AdExecute::Action
      requires :request, :ad_hash
      provides :click_key

      def execute
        request = context[:request]
        ad_hash = context[:ad_hash]

        # uid와 ad token을 조합하여 고유 클릭키 생성
        click_key = ClickKeyManager.encoded_click_key(request.uid, ad_hash[:token])
        context[:click_key] = click_key
        
        log_info "ClickKey 생성 완료: #{click_key}"
      end
    end
  end
end
