module AdExecute
  module Actions
    # request에서 uid와 ad_id를 추출하여 기본 파라미터 유효성을 검증한다.
    # uid 또는 ad_id가 blank이면 StandardError를 발생시켜 파이프라인을 중단한다.
    #
    # @context_requires [AdParticipateRequest] :request 참여 요청 DTO (uid, ad_id 포함)
    class ValidateUser < AdExecute::Action
      requires :request

      def execute
        request = context[:request]
        uid = request.uid
        ad_id = request.ad_id
        
        # 1차 파라미터 방어 로직 (기타 params.require 확인 등)
        if uid.blank? || ad_id.blank?
          raise AdisonErrors::BadRequest.new(Errors::INVALID_PARAMETER, options: { log_message: "Invalid Application Payload" })
        end
        
      end
    end
  end
end
