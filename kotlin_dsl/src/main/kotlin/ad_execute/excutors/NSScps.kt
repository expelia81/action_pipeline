package org.example.sample_kotlin.application.ad_execute.excutors

import org.example.sample_kotlin.application.ad_execute.AdParticipateRequest
import org.example.sample_kotlin.application.ad_execute.Executor
import org.example.sample_kotlin.application.ad_execute.actions.LoggingAction
import org.example.sample_kotlin.application.ad_execute.actions.PrepareParticipate
import org.example.sample_kotlin.application.ad_execute.dsl.SequenceNode
import org.example.sample_kotlin.application.ad_execute.dsl.buildSequence
import org.springframework.stereotype.Component

@Component
class NSScps : Executor() {
    override val sequence: List<SequenceNode> = buildSequence {
        action<PrepareParticipate>()
        action<LoggingAction>()
    }

    override fun execute(request: AdParticipateRequest) {
        val context = hashMapOf(
            "uid" to request.uid,
            "adId" to request.adId,
            "advertisingId" to request.advertisingId,
            "adType" to request.adType
        )
        executeInternally(context)
    }
}
