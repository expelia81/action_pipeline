package org.example.sample_kotlin.application.ad_execute

import org.example.sample_kotlin.application.ad_execute.executors.CpaParticipateExecutor
import org.example.sample_kotlin.application.ad_execute.executors.CpicParticipateExecutor
import org.example.sample_kotlin.application.ad_execute.excutors.NSScps
import org.springframework.stereotype.Component

/**
 * 호출자 단일 진입점(Unified Entry Point).
 * 
 * 외부(Controller 등)에서는 오직 이 컴포넌트만 알면 됩니다.
 * request.adType 정보에 따라 적절히 구성된 내부 Executor 파이프라인으로 트래픽을 라우팅합니다.
 */
@Component
class AdExecutorRouter(
    private val cpicExecutor: CpicParticipateExecutor,
    private val cpaExecutor: CpaParticipateExecutor,
    private val nsScpsExecutor: NSScps // 레거시 또는 특수 타겟 테스트용
) {
    fun execute(request: AdParticipateRequest) {
        val executor: Executor = when (request.adType.uppercase()) {
            "CPIC", "CPM" -> cpicExecutor
            "CPA", "CPE" -> cpaExecutor
            "NSSCPS" -> nsScpsExecutor
            else -> throw IllegalArgumentException("지원하지 않는 광고 타입입니다: ${request.adType}")
        }
        
        executor.execute(request)
    }
}
