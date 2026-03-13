module AdExecute
  module Executors
    class OfferwallCouponParticipateExecutor < AdExecute::Executor
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

          # 구버전 API 호환용 쿠폰 참여 캐시 생성
          action Actions::CacheOfferwallCoupon

          # 🚨주의: 쿠폰 API는 참여 실적(IncrementAdReport)을 즉시 차감하지 않습니다.
          # (사용 확정 시점에 별도로 처리됨)
        end

        action Actions::Macros::GenerateClientResponse
      end
    end
  end
end
