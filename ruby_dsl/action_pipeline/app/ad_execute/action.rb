module AdExecute
  # 파이프라인 실행 중 에러 없이 이후 단계를 중단할 때 사용하는 신호
  # 사용 예정은 없고, 아이디어용도.
  class Halt < StandardError; end

  # 모든 비즈니스 로직(검증, 기록, 포스트백 등)의 뼈대가 되는 부모 클래스
  class Action
    # Action 내부에서 context 접근을 requires/provides/optional 선언 범위로 제한하는 프록시.
    # - 읽기([]): requires, optional, provides에 선언된 키만 허용
    # - 쓰기([]=): provides에 선언된 키만 허용
    class Context
      def initialize(raw, required_keys, provided_keys, optional_keys)
        @raw           = raw
        @required_keys = required_keys
        @provided_keys = provided_keys
        @optional_keys = optional_keys
      end

      def [](key)
        unless @required_keys.include?(key) || @optional_keys.include?(key) || @provided_keys.include?(key)
          raise KeyError, "requires/optional/provides에 선언되지 않은 키: :#{key}"
        end

        @raw[key]
      end

      def []=(key, value)
        raise KeyError, "provides에 선언되지 않은 키: :#{key}" unless @provided_keys.include?(key)

        @raw[key] = value
      end
    end
    # 이 Action 실행 전 context에 반드시 존재해야 하는 키를 선언.
    # 순서 오류나 Action 누락 시 런타임 초기에 명시적 KeyError로 알려줌.
    def self.requires(*keys)
      @required_keys = keys
    end

    # 이 Action이 execute 후 context에 추가하는 키를 선언 (문서화 목적).
    def self.provides(*keys)
      @provided_keys = keys
    end

    # context에 있을 수도 없을 수도 있는 키를 선언.
    # requires와 달리 부재해도 validate_requirements!를 통과하지만,
    # ActionContext 프록시를 통한 읽기는 허용된다.
    def self.optional(*keys)
      @optional_keys = keys
    end

    def self.required_keys
      @required_keys || []
    end

    def self.provided_keys
      @provided_keys || []
    end

    def self.optional_keys
      @optional_keys || []
    end

    # action 자체 행동이 아니라 하위 action을 가질 수 있는 경우에 작성. execute를 오버라이드하면 무시되므로 주의.
    def self.sub_actions
      []
    end

    def initialize(raw_context)
      @raw_context = raw_context
      validate_requirements!
    end

    # requires/provides 범위로 접근이 제한된 context 프록시.
    # 하위 클래스에서 @raw_context 대신 context[key] 형태로 사용할 것.
    def context
      @context ||= Context.new(@raw_context, self.class.required_keys, self.class.provided_keys, self.class.optional_keys)
    end

    # 더 베스트는 매번 인스턴스 생성 없이 context를 파라미터로 전파하는 것이지만 이번 범위에서는 생략
    def execute
      if self.class.sub_actions.any?
        self.class.sub_actions.each do |sub_action_class|
          sub_action_class.new(@raw_context).execute
        end
      else
        raise NotImplementedError, "#{self.class} 에 execute 메서드가 구현되지 않았습니다."
      end
    end

    protected

    # 이후 파이프라인을 예외 없이 중단 (에러가 아닌 의도적 조기 종료)
    # 예: 이미 처리된 요청이라 남은 단계가 불필요할 때
    def halt!(message = nil)
      raise AdExecute::Halt, message
    end

    private

    def validate_requirements!
      missing = self.class.required_keys.reject { |k| @raw_context.key?(k) }
      raise KeyError, "#{self.class}: context에 필수 키가 없습니다 → #{missing}" if missing.any?
    end

    def log_info(message, extra = {})
      Rails.logger.info "[#{self.class.name.split('::').last}] #{message}", extra
    end

    def log_warn(message, extra = {})
      Rails.logger.warn "[#{self.class.name.split('::').last}] #{message}", extra
    end

    def log_error(message, extra = {})
      Rails.logger.error "[#{self.class.name.split('::').last}] #{message}", extra
    end
  end
end
