package org.example.sample_kotlin.application.ad_execute.executors

import org.example.sample_kotlin.application.ad_execute.AdParticipateRequest
import org.example.sample_kotlin.application.ad_execute.Executor
import org.example.sample_kotlin.application.ad_execute.actions.*
import org.example.sample_kotlin.application.ad_execute.dsl.SequenceNode
import org.example.sample_kotlin.application.ad_execute.dsl.buildSequence
import org.springframework.stereotype.Component

/**
 * [ 비동기 보상형 (CPA, CPE) 광고 참여 파이프라인 ]
 * 특징: 유저가 렌딩을 타는 단계 (참여) 까지만 진행하고, 실제 적립(포스트백)은 요청하지 않고 종료함.
 */
@Component
class CpaParticipateExecutor : Executor() {
    
    override val sequence: List<SequenceNode> = buildSequence {
        action<ValidateRequestAction>()
        action<LoadAdResourceAction>()
        action<ValidateDeviceAction>()
        action<CheckParticipatableAdAction>()
        action<CheckBlockUserAction>()
        action<CheckPublisherStatusAction>()

        withLock("adType", "adId") {
            action<CheckDuplicateParticipationAction>()
            action<ParticipateAdNetworkAction>()
            
            withTransaction {
                action<CreateParticipateRecordAction>()
            }
        }
        action<GenerateLandingUrlAction>()
        // RequestPostbackAction 가 제외됨
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

