package org.example.sample_kotlin.application.ad_execute

import org.example.sample_kotlin.application.ad_execute.actions.WithDistributedLockAction
import org.example.sample_kotlin.application.ad_execute.actions.WithTransactionAction
import org.example.sample_kotlin.application.ad_execute.dsl.ActionNode
import org.example.sample_kotlin.application.ad_execute.dsl.SequenceNode
import org.example.sample_kotlin.application.ad_execute.dsl.WrapperNode
import org.springframework.beans.factory.NoSuchBeanDefinitionException
import org.springframework.context.ApplicationContext
import org.springframework.context.event.ContextRefreshedEvent
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

@Component
class ExecutorStartupValidator(
    private val applicationContext: ApplicationContext,
    private val executors: List<Executor>,
    private val actions: List<Action>,
) {

    @EventListener(ContextRefreshedEvent::class)
    fun initialize() {
        // 1. 모든 Action 인터페이스 구현체들의 preActions 의존성 빈 등록 여부 검증
        actions.forEach { action ->
            action.preActions.forEach { preAction ->
                try {
                    applicationContext.getBean(preAction.java)
                } catch (e: NoSuchBeanDefinitionException) {
                    throw IllegalStateException(
                        "action : [${action::class.simpleName}] ${preAction.simpleName}이 Spring 빈으로 등록되지 않았습니다.",
                        e,
                    )
                }
            }
        }

        // 2. 각 Executor의 DSL Sequence를 파싱하여 Action 트리를 조립하고 제약조건 검증
        executors.forEach { executor ->
            executor.actions = buildActionTree(executor.sequence, executor::class.simpleName ?: "Unknown")
            executor.validateActionOrders()
        }
    }

    // DSL 노드(트리)를 실제 Spring Bean 인스턴스 트리로 변환(재귀 탐색)
    private fun buildActionTree(nodes: List<SequenceNode>, executorName: String): List<Action> {
        return nodes.map { node ->
            when (node) {
                is ActionNode -> getBeanOrThrow(node.actionClass, executorName)
                is WrapperNode -> {
                    val wrapperAction = getBeanOrThrow(node.wrapperClass, executorName)
                    val childActions = buildActionTree(node.children, executorName)
                    
                    // 래퍼 액션에 자식들을 주입
                    if (wrapperAction is WithDistributedLockAction) {
                        wrapperAction.childActions = childActions
                    } else if (wrapperAction is WithTransactionAction) {
                        wrapperAction.childActions = childActions
                    }
                    
                    // DSL 노드 전용 동적 런타임 설정 주입 (예: 커스텀 락 키 제너레이터)
                    node.configurer?.invoke(wrapperAction)
                    
                    wrapperAction
                }
            }
        }
    }

    private fun getBeanOrThrow(actionClass: KClass<out Action>, executorName: String): Action {
        try {
            return applicationContext.getBean(actionClass.java)
        } catch (e: NoSuchBeanDefinitionException) {
            throw IllegalStateException(
                "executor : [$executorName] ${actionClass.simpleName}이 Spring 빈으로 등록되지 않았습니다.",
                e,
            )
        }
    }
}

// 트리 구조를 완전 평탄화(Flatten)하여 preAction 순서 논리가 지켜졌는지 검사
private fun Executor.validateActionOrders() {
    val flatClasses = sequence.flatMap { it.classesRequired }
    val seen = mutableSetOf<Class<out Action>>()
    
    for (actionClass in flatClasses) {
        // 등록된 빈 중에서 해당 클래스의 메타데이터(preActions)를 찾음 (기능적 우회 조회)
        // 실제 프로덕션에서는 flatClasses 순회를 Bean 트리 순회와 결합하여 검증하는 편이 효율적입니다.
    }
    
    // 단순화된 트리 순회 검증을 위해 런타임 인스턴스 트리를 평탄화하여 검증합니다.
    val flatActions = flattenActions(this.actions)
    
    for (action in flatActions) {
        for (preAction in action.preActions) {
            check(preAction.java in seen) {
                "[${this::class.simpleName}] ${preAction.simpleName}은 ${action::class.simpleName} 이전에 선언되어야 합니다."
            }
        }
        seen.add(action::class.java)
    }
}

// 런타임 트리를 평탄화(Flatten)하는 재귀 함수
private fun flattenActions(actions: List<Action>): List<Action> {
    val flatList = mutableListOf<Action>()
    for (action in actions) {
        flatList.add(action)
        when (action) {
            is WithDistributedLockAction -> flatList.addAll(flattenActions(action.childActions))
            is WithTransactionAction -> flatList.addAll(flattenActions(action.childActions))
        }
    }
    return flatList
}

