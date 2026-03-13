module AdExecute
  class DependencyError < StandardError; end

  class PipelineValidator
    # 파이프라인 시작 시 기본적으로 주어지는 Context 파라미터들
    INITIAL_CONTEXT_KEYS = [:request, :ad_type, :uid, :ad_id, :advertising_id].freeze

    def self.validate!(executor_class, action_classes)
      available_keys = INITIAL_CONTEXT_KEYS.dup

      action_classes.each do |action_class|
        validate_action_dependencies!(executor_class, action_class, available_keys)
        
        # 제공하는 키가 있다면 머지
        if action_class.provided_keys.any?
          available_keys.concat(action_class.provided_keys).uniq!
        end
      end

      true
    end

    private

    def self.validate_action_dependencies!(executor_class, action_class, available_keys)
      child_actions = action_class.respond_to?(:sub_actions) ? action_class.sub_actions : []
      
      if child_actions.any?
        # 매크로 액션인 경우 내부 액션들의 의존성도 검증
        internal_available_keys = available_keys.dup
        child_actions.each do |child_action|
          validate_action_dependencies!(executor_class, child_action, internal_available_keys)
          internal_available_keys.concat(child_action.provided_keys).uniq!
        end

        # 매크로 자체가 선언한 required_keys도 검증 (상위 수준 의존성)
        missing_keys = action_class.required_keys - available_keys
      else
        missing_keys = action_class.required_keys - available_keys
      end

      if missing_keys.any?
        raise DependencyError, 
              "[#{executor_class.name}] 파이프라인 순서 오류: #{action_class.name} 실행을 위해 #{missing_keys} 데이터가 필요하지만, " \
              "해당 파이프라인의 이전 단계 어디에서도 제공(provides)되거나 초기 context에 선언되지 않았습니다. " \
              "(현재 사용 가능한 키: #{available_keys})"
      end
    end
  end
end
