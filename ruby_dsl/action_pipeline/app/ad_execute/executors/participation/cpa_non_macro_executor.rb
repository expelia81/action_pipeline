module AdExecute
  module Executors
    # 발표용 시연(비교) 클래스입니다. 실제 라우터(AdExecutorRouter)에는 등록되지 않습니다.
    # Macro Action을 결합하기 전, 가장 기초적인(파편화된) 형태로
    # 모든 개별 Action을 일일이 나열했을 때의 코드를 보여주기 위한 용도입니다.
    class CpaNonMacroExecutor < AdExecute::Executor
      include AdExecute::Concerns::LockManager
      include AdExecute::Concerns::TransactionManager

      def define_sequence
        # 1. 7종 공통 사전 검증 (파편화)
        action Actions::ValidateUser
        action Actions::LoadAdResource
        action Actions::ValidateDevice
        action Actions::CheckParticipatableAd
        action Actions::CheckAlreadyCompleted
        action Actions::CheckBlockUser
        action Actions::CheckPublisherStatus

        # 2. 참여 컨텍스트 준비 (파편화)
        action Actions::GenerateClickKey
        action Actions::PreprocessParticipation

        # 3. 데이터베이스 상태 변이 (Side-Effect 바운더리)
        with_lock(:ad_id, :uid) do
          action Actions::CheckDuplicateParticipation
          action Actions::ParticipateAdNetwork

          with_transaction do
            action Actions::CreateParticipateRecord
          end

          action Actions::IncrementAdReport
        end

        # 4. 최종 클라이언트 응답 생성 (파편화)
        action Actions::GenerateLandingUrl
        action Actions::GenerateSdkDialog
        
        # CPA는 즉시 포스트백 없음
      end
    end
  end
end
