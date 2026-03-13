package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logRequestPostback = mu.KotlinLogging.logger {}

@Component
class RequestPostbackAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(GenerateLandingUrlAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val uid = context["uid"]
        val adId = context["adId"]
        
        logRequestPostback.info("[RequestPostbackAction] 즉시 보상을 위한 포스트백(적립) 요청을 호출합니다. (CPC/CPM 대상) - uid=$uid, adId=$adId")
        context["rewardStatus"] = "POSTBACK_REQUESTED"
    }
}
