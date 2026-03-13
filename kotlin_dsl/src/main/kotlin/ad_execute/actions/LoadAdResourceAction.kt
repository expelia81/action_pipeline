package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logLoadAdResource = mu.KotlinLogging.logger {}

@Component
class LoadAdResourceAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(ValidateRequestAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val adId = context["adId"]
        logLoadAdResource.info("[LoadAdResourceAction] 해당 광고 리소스 존재 여부 및 활성 상태를 조회합니다. adId=$adId")
        
        // Mock DB fetch
        context["adType"] = "CPC"
        context["adToken"] = "token123"
    }
}
