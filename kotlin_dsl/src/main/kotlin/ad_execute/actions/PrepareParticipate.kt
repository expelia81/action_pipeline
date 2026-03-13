package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

// 구현 예시용
@Component
class PrepareParticipate : Action {
    override val preActions: List<KClass<out Action>> = listOf()

    override fun execute(
        context: HashMap<String, String>,
        actions: List<Action>
    ) {
        context["participate"] = "true"
    }
}
