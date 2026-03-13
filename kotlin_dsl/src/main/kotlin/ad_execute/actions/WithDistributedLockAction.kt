package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.context.annotation.Scope
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logWithLock = mu.KotlinLogging.logger {}

/**
 * 분산락을 획득하고 내부의 자식(child) Action 들만 실행한 후, 
 * 예외 발생 여부와 상관없이 안전하게 락을 해제하는 래퍼(Wrapper/Decorator) Action.
 * 
 * *주의*: 이 Action은 DSL의 WrapperNode로서 런타임에 children을 주입받아 동작합니다.
 * @Scope("prototype")을 통해 DSL 노드 구성 시마다 새로운 상태(childActions, keyGenerator)를 독립적으로 가집니다.
 */
@Component
@Scope("prototype") // 빈 생성을 호출할 때마다 매번 새로 생성되도록 강제
class WithDistributedLockAction : Action {
    override val preActions: List<KClass<out Action>> = emptyList()

    // 런타임에 동적으로 주입될 자식 액션들
    var childActions: List<Action> = emptyList()
    
    // 외부에 의해 런타임에 주입될 수 있는 유연한 락 키 생성기
    var lockKeyGenerator: (HashMap<String, String>) -> String = { context -> 
        val uid = context["uid"] ?: "unknown"
        val adId = context["adId"] ?: "unknown"
        "LOCK_${adId}_${uid}"
    }

    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        val lockKey = lockKeyGenerator(context)
        
        logWithLock.info("====================================")
        logWithLock.info("[WithDistributedLockAction] 🔒 [$lockKey] 획득 시도 (동시성 제어 시작)")
        
        try {
            // 자식 액션들을 트리 안에서 순차 실행
            childActions.forEach { it.execute(context, childActions) }
        } finally {
            logWithLock.info("[WithDistributedLockAction] 🔓 [$lockKey] 안전 해제 (동시성 제어 종료)")
            logWithLock.info("====================================")
        }
    }
}
