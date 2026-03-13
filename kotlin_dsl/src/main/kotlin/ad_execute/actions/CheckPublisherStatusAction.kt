package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logCheckPublisher = mu.KotlinLogging.logger {}

@Component
class CheckPublisherStatusAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(CheckBlockUserAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        logCheckPublisher.info("[CheckPublisherStatusAction] 매체측 서버(API)에 해당 유저의 참여 가능 여부를 확인합니다.")
    }
}
