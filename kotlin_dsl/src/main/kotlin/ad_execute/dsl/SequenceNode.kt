package org.example.sample_kotlin.application.ad_execute.dsl

import org.example.sample_kotlin.application.ad_execute.Action
import kotlin.reflect.KClass

/**
 * DSL을 구성하는 각 요소(노드)를 나타냅니다.
 * 일반적인 Action 클래스 하나일 수도 있고(ActionNode),
 * 트랜잭션/락과 같이 하위 Action들을 갖는 Wrapper 블록일 수도 있습니다(WrapperNode).
 */
sealed class SequenceNode {
    abstract val classesRequired: List<KClass<out Action>>
}

class ActionNode(val actionClass: KClass<out Action>) : SequenceNode() {
    override val classesRequired = listOf(actionClass)
}

class WrapperNode(
    val wrapperClass: KClass<out Action>, // e.g. WithLockAction::class
    val children: List<SequenceNode>,
    val configurer: ((Action) -> Unit)? = null
) : SequenceNode() {
    override val classesRequired: List<KClass<out Action>>
        get() = listOf(wrapperClass) + children.flatMap { it.classesRequired }
}
