module AdExecute
  class AdExecutorRouter
    # 광고 타입 → Executor 클래스 매핑 레지스트리.
    EXECUTOR_REGISTRY = {
      # --- 앱 설치/실행형 (CPI 계열: 사후 포스트백. 즉시 포스트백 없음) ---
      'CPIC'                  => Executors::CpiParticipateExecutor,
      'CPI'                   => Executors::CpiParticipateExecutor,
      'CPF'                   => Executors::CpiParticipateExecutor,
      'CPQ'                   => Executors::CpiParticipateExecutor,
      'KAKAOTALK_CHANNEL_ADD' => Executors::CpiParticipateExecutor,
      'AOG_MULTI_REWARD'      => Executors::CpiParticipateExecutor,
      'NEPTUNE_VIDEO'         => Executors::CpiParticipateExecutor,

      # --- 클릭/노출형 (CPC/CPM 계열: 참여 즉시 포스트백 발생) ---
      'CPC'                   => Executors::CpcParticipateExecutor,
      'CPC_ACCUMULATE'        => Executors::CpcParticipateExecutor,
      'CPM'                   => Executors::CpcParticipateExecutor,

      # --- 비동기 성과형 (CPA/CPS 계열: 즉시 포스트백 없음) ---
      'CPA'                                         => Executors::CpaParticipateExecutor,
      'CPE'                                         => Executors::CpaParticipateExecutor,
      'CPA_S2S'                                     => Executors::CpaParticipateExecutor,
      'CPA_TRACKER'                                 => Executors::CpaParticipateExecutor,
      'CPA_BRIDGE'                                  => Executors::CpaParticipateExecutor,
      'CPA_SUBSCRIBE'                               => Executors::CpaParticipateExecutor,
      'CPA_SNS_VIRAL'                               => Executors::CpaParticipateExecutor,
      'CPA_S2S_ACCUMULATE'                          => Executors::CpaParticipateExecutor,
      'CPA_TRACKER_ACCUMULATE'                      => Executors::CpaParticipateExecutor,
      'COOKIE_OVEN_SMARTSTORE_CPS'                  => Executors::CpaParticipateExecutor,
      'COOKIE_OVEN_PLACE_ORDER_BOOKING'             => Executors::CpaParticipateExecutor,
      'COOKIE_OVEN_SMARTSTORE_CPS_PURCHASE_CONFIRM' => Executors::CpaParticipateExecutor,

      # --- 네이버페이 포인트 보장형 CPS (고유 토큰 발급 필요) ---
      'NAVERPAY_POINTGUARANTEE_CPS_BOOSTING'        => Executors::NpcbParticipateExecutor,

      # --- 오퍼월 쿠폰 전용 파이프라인 (참여 실적 리포트 CAP 차감 없음) ---
      'CPA_COUPON'                                  => Executors::OfferwallCouponParticipateExecutor,

      # --- 네이버페이 전용 성과형 (CPA 계열 + AOT 리포트 집계 추가) ---
      'NAVERPAY_SMARTSTORE_CPS'                     => Executors::NaverpayAotParticipateExecutor,
      'NAVERPAY_SMARTSTORE_CPS_PURCHASE_CONFIRM'    => Executors::NaverpayAotParticipateExecutor,
      'NAVERSHOPPING_AFFILIATE'                     => Executors::NaverpayAotParticipateExecutor,
      'NAVERSHOPPING_AFFILIATE_PURCHASE_CONFIRM'    => Executors::NaverpayAotParticipateExecutor,
    }.freeze

    # 클래스 로드 시점에 즉시 캐싱하여 앱 부트 시점에 의존성 검증(PipelineValidator)이 트리거되게 합니다.
    @executors = EXECUTOR_REGISTRY.transform_values(&:new).freeze

    def self.execute(request)
      executor = @executors[request.ad_type.upcase]
      raise ArgumentError, "지원하지 않는 광고 타입입니다: #{request.ad_type}" unless executor

      executor.execute(request)
    end
    
    # 이니셜라이저 등에서 파이프라인 검증용으로 호출하기 위한 진입점 (클래스 강제 로드)
    def self.validate_boot!
      @executors.keys
    end
  end
end
