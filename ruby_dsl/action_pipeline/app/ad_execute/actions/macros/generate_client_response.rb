module AdExecute
  module Actions
    module Macros
      # GenerateLandingUrl과 GenerateSdkDialog를 하나로 묶은 병합 액션(Macro Action).
      # 파이프라인 전역에서 응답 생성을 위해 항상 한 세트로 호출되므로 응집도를 위해 통합됨.
      # 클라이언트에 최종적으로 내려줄 랜딩 URL과 SDK 다이얼로그(Alert) 정보를 생성한다.
      class GenerateClientResponse < AdExecute::Action
        requires :request, :ad_hash, :publisher_app_hash, :click_key
        provides :landing_url, :sdk_dialog
        
        def self.sub_actions
          [
            Actions::GenerateLandingUrl,
            Actions::GenerateSdkDialog
          ]
        end
      end
    end
  end
end
