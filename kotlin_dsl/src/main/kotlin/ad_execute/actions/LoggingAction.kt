package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val log = mu.KotlinLogging.logger {}

// 구현 예시용
@Component
class LoggingAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(
        PrepareParticipate::class,
    )


    override fun execute(
        context: HashMap<String, String>,
        actions: List<Action>
    ) {
        val contextString = context.entries.joinToString(separator = ", ") { "${it.key}=${it.value}" }
        val actionsString = actions.joinToString(separator = ", ") { it.javaClass.simpleName }
        log.info("context: $contextString, actions: $actionsString")
    }

}
