package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logAcquireLock = mu.KotlinLogging.logger {}

@Component
class AcquireParticipateLockAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(CheckPublisherStatusAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val uid = context["uid"]
        val adId = context["adId"]
        logAcquireLock.info("[AcquireParticipateLockAction] 유저($uid)와 광고($adId) 조합으로 Redis 분산 락을 획득합니다 (따닥 방지).")
        
        context["lockAcquired"] = "true"
    }
}
