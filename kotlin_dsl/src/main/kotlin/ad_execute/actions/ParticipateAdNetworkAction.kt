package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logParticipateAdNetwork = mu.KotlinLogging.logger {}

@Component
class ParticipateAdNetworkAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(CheckDuplicateParticipationAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        logParticipateAdNetwork.info("[ParticipateAdNetworkAction] 애드네트워크 연동 광고일 경우 서드파티 참여 가능 여부를 확인합니다.")
    }
}
