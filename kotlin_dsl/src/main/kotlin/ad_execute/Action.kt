package org.example.sample_kotlin.application.ad_execute

import kotlin.reflect.KClass

interface Action {
    val preActions : List<KClass<out Action>> // 해당 액션 전에 반드시 수행되어야하는 액션으로, 그렇게 선언되지 않은 경우 실행기는 존재할 수 없다.
    fun execute(context : HashMap<String, String>, actions : List<Action>)
}
