package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logReleaseLock = mu.KotlinLogging.logger {}

@Component
class ReleaseParticipateLockAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(GenerateLandingUrlAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val lockAcquired = context["lockAcquired"]?.toBoolean() ?: false
        if(lockAcquired) {
            logReleaseLock.info("[ReleaseParticipateLockAction] 참여 진행 중 잡아두었던 Redis 분산 락을 안전하게 해제합니다.")
            context.remove("lockAcquired")
        }
    }
}
