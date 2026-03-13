package org.example.sample_kotlin.application.ad_execute.actions

import org.example.sample_kotlin.application.ad_execute.Action
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

val logWithTransaction = mu.KotlinLogging.logger {}

/**
 * 선언적 데이터베이스 트랜잭션(@Transactional) 범위를 규정하는 래퍼(Wrapper) Action.
 * 
 * *주의*: 실제 DB 연동 환경에서는 execute 메서드나 Service 레이어 위탁을 통해 
 * Spring의 @Transactional 처리가 발생되도록 설계되어야 합니다.
 */
@Component
class WithTransactionAction : Action {
    override val preActions: List<KClass<out Action>> = emptyList()

    var childActions: List<Action> = emptyList()

    // 실제 프로덕션에서는 내부 호출로 트랜잭션 프록시가 걸리지 않으므로,
    // (self-invocation 이슈), 별도의 Transactional Service 빈을 주입받아
    // runInTransaction { ... } 형식으로 우회하거나,
    // AspectJ 기반 CGLIB 위빙을 구성해야 합니다.
    // 여기서는 개념 증명을 위해 로그로 감쌉니다.
    // @Transactional
    override fun execute(context: HashMap<String, String>, actions: List<Action>) {
        logWithTransaction.info("   >>> [WithTransactionAction] 트랜잭션 범위(TX) BEGIN")
        
        try {
            // DB 변경 등이 일어나는 자식 액션들 실행
            childActions.forEach { it.execute(context, childActions) }
            
            logWithTransaction.info("   >>> [WithTransactionAction] 트랜잭션 범위(TX) COMMIT완료")
        } catch (e: Exception) {
            logWithTransaction.error("   >>> [WithTransactionAction] 처리 중 예외 발생, 트랜잭션 범위(TX) ROLLBACK!")
            throw e
        }
    }
}
