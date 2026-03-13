package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logGenerateUrl = mu.KotlinLogging.logger {}

@Component
class GenerateLandingUrlAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(CreateParticipateRecordAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val clickKey = context["clickKey"]
        val landingUrl = "https://tracker.com/landing?ck=$clickKey"
        context["landingUrl"] = landingUrl
        
        logGenerateUrl.info("[GenerateLandingUrlAction] 매크로 치환을 통해 최종 트래킹 랜딩 URL 생성 완료: $landingUrl")
    }
}
