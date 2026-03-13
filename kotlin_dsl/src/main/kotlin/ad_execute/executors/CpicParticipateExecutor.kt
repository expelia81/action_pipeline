package org.example.sample_kotlin.application.ad_execute.executors

import org.example.sample_kotlin.application.ad_execute.AdParticipateRequest
import org.example.sample_kotlin.application.ad_execute.Executor
import org.example.sample_kotlin.application.ad_execute.actions.*
import org.example.sample_kotlin.application.ad_execute.dsl.SequenceNode
import org.example.sample_kotlin.application.ad_execute.dsl.buildSequence
import org.springframework.stereotype.Component

/**
 * [ 즉시 보상형 (CPC, CPM) 광고 참여 파이프라인 ]
 * 특징: 참여 로직 마지막에 즉시 포스트백(보상 적립)을 요청함.
 */
@Component
class CpicParticipateExecutor : Executor() {
    
    override val sequence: List<SequenceNode> = buildSequence {
        action<ValidateRequestAction>()
        action<LoadAdResourceAction>()
        action<ValidateDeviceAction>()
        action<CheckParticipatableAdAction>()
        action<CheckBlockUserAction>()
        action<CheckPublisherStatusAction>()

        // ------------------ (동시성 제어 보호 구역) ------------------
        withLock("adType", "adId", "uid") {
            action<CheckDuplicateParticipationAction>()
            action<ParticipateAdNetworkAction>()
            
            // ----------- (트랜잭션 쓰기 구역) -----------
            withTransaction {
                action<CreateParticipateRecordAction>()
            }
        }
        
        action<GenerateLandingUrlAction>()
        action<RequestPostbackAction>() // CPC/CPM용: 즉시 적립 포스트백
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

