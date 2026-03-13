module AdExecute
  module Executors
    # 네이버페이 AOT(Affiliate Order Tracking) 기반 파이프라인.
    # 대상: NAVERPAY_SMARTSTORE_CPS, NAVERPAY_SMARTSTORE_CPS_PURCHASE_CONFIRM,
    #       NAVERSHOPPING_AFFILIATE, NAVERSHOPPING_AFFILIATE_PURCHASE_CONFIRM
    #
    # 부스팅 토큰(referenced_npcb_p_token)은 CPS 타입에서만 허용되며,
    # ConsumeNpcbBoostToken 액션 내부에서 광고타입별 허용 여부를 검증한다.
    class NaverpayAotParticipateExecutor < AdExecute::Executor
      include Concerns::LockManager
      include Concerns::TransactionManager

      def define_sequence
        action Actions::Macros::CommonPreValidate

        action Actions::ValidateNaverpayAotParams
        action Actions::ConsumeNpcbBoostToken
        action Actions::Macros::PrepareParticipationContext

        with_lock(:ad_id, :uid) do
          action Actions::CheckDuplicateParticipation
          action Actions::ParticipateAdNetwork

          with_transaction do
            action Actions::CreateParticipateRecord
            action Actions::CreateNaverpayAotParticipate
          end

          action Actions::IncrementAdReport
          action Actions::IncrementNaverpayAotAdReport
        end

        action Actions::Macros::GenerateClientResponse
      end
    end
  end
end
