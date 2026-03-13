package org.example.sample_kotlin.application.ad_execute

import org.example.sample_kotlin.application.ad_execute.dsl.SequenceNode

abstract class Executor {
    // 1차원 KClass 배열에서 DSL 기반의 계층형 노드 리스트로 변경
    abstract val sequence: List<SequenceNode>
    
    // 컴포지트 패턴을 통해 조립된 런타임 Action 인스턴스 트리
    var actions: List<Action> = emptyList()
        internal set

    /**
     * 외부 호출자가 호출해야 하는 공통 규격입니다.
     */
    abstract fun execute(request: AdParticipateRequest)

    /**
     * 하위 Executor 구현체들이 조립된 Action 트리를 실행할 때 사용하는 내부 헬퍼 메서드입니다.
     */
    protected fun executeInternally(context: HashMap<String, String>) {
        actions.forEach { it.execute(context, actions) }
    }
}


