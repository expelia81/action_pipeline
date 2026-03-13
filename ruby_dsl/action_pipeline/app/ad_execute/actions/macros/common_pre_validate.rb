module AdExecute
  module Actions
    module Macros
      # 사전 참여 자격을 검증하는 7종 세트를 병합한 매크로 액션.
      # 파이프라인 전반에서 항상 최상단에 함께 위치하는 필수 검증 요소들을 통합함.
      class CommonPreValidate < AdExecute::Action
        requires :request, :uid, :ad_id, :ad_type, :advertising_id

        # 하위 액션들이 제공(provides)하는 모든 것들을 명시적으로 전달받음
        provides :ad_hash, :ad_type_hash, :publisher_app_hash, :membership_id
        
        def self.sub_actions
          [
            Actions::ValidateUser,
            Actions::LoadAdResource,
            Actions::ValidateCommonParams,
            Actions::ValidateDevice,
            Actions::CheckParticipatableAd,
            Actions::CheckAlreadyCompleted,
            Actions::ValidateIdfaTracking,
            Actions::CheckBlockUser,
            Actions::CheckPublisherStatus
          ]
        end
      end
    end
  end
end
