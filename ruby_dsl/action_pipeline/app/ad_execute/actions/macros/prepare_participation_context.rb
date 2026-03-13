module AdExecute
  module Actions
    module Macros
      # GenerateClickKey와 PreprocessParticipation을 하나로 묶은 병합 액션(Macro Action).
      # 파이프라인 전역에서 항상 한 세트로 호출되므로 응집도를 위해 통합됨.
      # 클릭 키를 생성하고 그 키를 바탕으로 광고 타입별 전처리를 수행한다.
      class PrepareParticipationContext < AdExecute::Action
        requires :request, :uid, :ad_hash, :ad_type_hash, :publisher_app_hash
        provides :click_key
        
        def self.sub_actions
          [
            Actions::GenerateClickKey,
            Actions::PreprocessParticipation
          ]
        end
      end
    end
  end
end
