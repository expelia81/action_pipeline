package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logValidateRequest = mu.KotlinLogging.logger {}

@Component
class ValidateRequestAction : Action {
    override val preActions: List<KClass<out Action>> = emptyList()

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val uid = context["uid"] ?: throw IllegalArgumentException("uid 파라미터가 누락되었습니다.")
        val adId = context["adId"] ?: throw IllegalArgumentException("adId 파라미터가 누락되었습니다.")
        
        logValidateRequest.info("[ValidateRequestAction] 요청 파라미터 검증 완료: uid=$uid, adId=$adId")
    }
}
