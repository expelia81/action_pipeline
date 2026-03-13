package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logCheckParticipatable = mu.KotlinLogging.logger {}

@Component
class CheckParticipatableAdAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(ValidateDeviceAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        logCheckParticipatable.info("[CheckParticipatableAdAction] 타겟팅, 광고 노출 시간, Cap (일일/전체 수량) 등을 검사합니다.")
    }
}
