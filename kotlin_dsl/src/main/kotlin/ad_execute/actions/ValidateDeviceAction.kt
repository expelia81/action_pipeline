package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logValidateDevice = mu.KotlinLogging.logger {}

@Component
class ValidateDeviceAction : Action {
    override val preActions: List<KClass<out Action>> = listOf(LoadAdResourceAction::class)

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val advertisingId = context["advertisingId"]
        
        logValidateDevice.info("[ValidateDeviceAction] 디바이스 IDFA 0값 체크 등 GAID 추적 제한 여부를 검사합니다. gaid=$advertisingId")
    }
}
