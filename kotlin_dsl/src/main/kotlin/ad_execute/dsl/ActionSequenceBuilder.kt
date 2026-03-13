package org.example.sample_kotlin.application.ad_execute.dsl

import org.example.sample_kotlin.application.ad_execute.Action
import org.example.sample_kotlin.application.ad_execute.actions.WithDistributedLockAction
import org.example.sample_kotlin.application.ad_execute.actions.WithTransactionAction
import kotlin.reflect.KClass

@DslMarker
annotation class SequenceDsl

@SequenceDsl
class ActionSequenceBuilder {
    @PublishedApi
    internal val nodes = mutableListOf<SequenceNode>()

    // 일반 액션 노드 추가
    inline fun <reified T : Action> action() {
        nodes.add(ActionNode(T::class))
    }
    
    // 특정 클래스를 직접 인자로 받는 액션 노드 추가
    fun action(actionClass: KClass<out Action>) {
        nodes.add(ActionNode(actionClass))
    }

    // 락 (분산 락) 블록 정의
    // 사용 예: withLock("adId", "uid") { ... }
    fun withLock(
        vararg contextKeys: String,
        init: ActionSequenceBuilder.() -> Unit
    ) {
        val childBuilder = ActionSequenceBuilder()
        childBuilder.init()
        nodes.add(
            WrapperNode(WithDistributedLockAction::class, childBuilder.build()) { wrapperAction ->
                if (wrapperAction is WithDistributedLockAction && contextKeys.isNotEmpty()) {
                    wrapperAction.lockKeyGenerator = { context ->
                        // 입력받은 키값들을 조합해서 자동 락 키 생성 (예: lock:1234:user567)
                        val values = contextKeys.map { key -> context[key] ?: "unknown" }
                        "lock:${values.joinToString(":")}"
                    }
                }
            }
        )
    }

    // 트랜잭션 블록 정의
    fun withTransaction(init: ActionSequenceBuilder.() -> Unit) {
        val childBuilder = ActionSequenceBuilder()
        childBuilder.init()
        nodes.add(WrapperNode(WithTransactionAction::class, childBuilder.build()))
    }

    fun build(): List<SequenceNode> = nodes.toList()
}

// 최상위 진입점
fun buildSequence(init: ActionSequenceBuilder.() -> Unit): List<SequenceNode> {
    val builder = ActionSequenceBuilder()
    builder.init()
    return builder.build()
}
