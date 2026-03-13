package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logCheckBlock = mu.KotlinLogging.logger {}

@Component
class CheckBlockUserAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(CheckParticipatableAdAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val uid = context["uid"]
        logCheckBlock.info("[CheckBlockUserAction] 매체별 차단 유저(블랙리스트) 여부를 검사합니다. uid=$uid")
    }
}
