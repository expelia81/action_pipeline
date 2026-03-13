module AdExecute
  module Executors
    class NpcbParticipateExecutor < AdExecute::Executor
      include AdExecute::Concerns::LockManager
      include AdExecute::Concerns::TransactionManager

      def define_sequence
        action Actions::Macros::CommonPreValidate
        action Actions::GenerateNpcbToken
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

        # 포인트 보장형 광고이므로 참여에 성공했다면 본인의 토큰을 캐싱하여 다음 유저 부스팅에 사용케 함
        action Actions::CacheNpcbBoostingToken
        # CPA 계열이므로 즉시 포스트백 없음
      end
    end
  end
end
