package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logCheckDuplicate = mu.KotlinLogging.logger {}

@Component
class CheckDuplicateParticipationAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(CheckParticipatableAdAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val uid = context["uid"]
        logCheckDuplicate.info("[CheckDuplicateParticipationAction] 유저($uid)가 해당 캠페인에 이미 참여를 완료했는지, 또는 지연 적립 상태인지 검사합니다.")
    }
}
