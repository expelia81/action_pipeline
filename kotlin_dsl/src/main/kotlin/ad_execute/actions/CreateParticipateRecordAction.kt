package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass
import java.util.UUID

val logCreateRecord = mu.KotlinLogging.logger {}

@Component
class CreateParticipateRecordAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(ParticipateAdNetworkAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val clickKey = UUID.randomUUID().toString()
        context["clickKey"] = clickKey
        
        logCreateRecord.info("[CreateParticipateRecordAction] DB 참여 이력 생성 및 트래커 핑(Ping) 전송. clickKey=$clickKey")
    }
}
