package org.example.sample_kotlin.application.ad_execute

/**
 * 광고 참여에 필요한 모든 정보를 담고 있는 데이터 전송 객체 (공통 페이로드)
 * 호출자(Controller, 외부 Service)는 개별 Executor를 몰라도 이 객체만 만들어서 라우터에 넘기면 됩니다.
 */
data class AdParticipateRequest(
    val adType: String,      // 예: "CPIC", "CPA", "CPM" 등
    val uid: String,         // 사용자 식별자
    val adId: String,        // 광고 모델 식별자
    val advertisingId: String // 모바일 광고 ID (IDFA, GAID 등)
)
