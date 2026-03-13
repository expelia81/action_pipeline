module AdExecute
  module Executors
    class CpiParticipateExecutor < AdExecute::Executor
      include AdExecute::Concerns::LockManager
      include AdExecute::Concerns::TransactionManager

      def define_sequence
        action Actions::Macros::CommonPreValidate
        action Actions::Macros::PrepareParticipationContext

        with_lock(:ad_id, :uid) do
          action Actions::CheckDuplicateParticipation
          action Actions::ParticipateAdNetwork

          with_transaction do
            action Actions::CreateParticipateRecord
          end

          # DB 트랜잭션 밖이지만, 분산 락(Lock) 내부에서 실행하여 동시성 CAP 정합성 보장
          action Actions::IncrementAdReport
        end

        action Actions::Macros::GenerateClientResponse
        # 즉시 포스트백은 CPC/CPM 에만 해당되므로 여기서는 제거
      end
    end
  end
end
