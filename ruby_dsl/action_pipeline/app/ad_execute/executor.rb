module AdExecute
  # 루비의 블록(yield)과 instance_eval을 활용한 놀랍도록 가벼운 DSL Executor
  class Executor
    def initialize
      @sequence_blocks = [] # 런타임에 실행할 Proc(블록) 들의 목록
      @action_classes = []  # 유효성 검증용 액션 클래스 순서 목록
      # @pre_action_classes = [] # 최초에는 정밀한 유효성 검증을 위해 도입 고려했으나 복잡성 줄이기 위해 제거
      
      define_sequence       # 상속받은 자식 클래스의 DSL 문구들을 평가하여 배열로 적재
      validate_pipeline!    # DSL 평가 후 즉시 의존성(requires/provides) 검증

      Rails.logger.info "[Executor] 🚀 [#{self.class.name}] 인스턴스 생성 및 검증 완료"
    end

    def define_sequence
      raise NotImplementedError, "define_sequence 를 구현하여 액션 파이프라인을 구성하세요."
    end
    
    # 외부(라우터 등)에서 호출하는 단일 진입점
    def execute(request)
      # 요청마다 독립적인 Context 생성 (인스턴스 변수 미사용 → 스레드 안전)
      context = {
        request: request,
        ad_type: request.ad_type,
        uid: request.uid,
        ad_id: request.ad_id,
        advertising_id: request.advertising_id
      }

      start_total = Time.now
      Rails.logger.info "[Executor] 🚀 [#{self.class.name}] 파이프라인 시작 (UID: #{context[:uid]})"

      @sequence_blocks.each do |block|
        block.call(context)
      end

      total_time = ((Time.now - start_total) * 1000).round(2)
      Rails.logger.info "[Executor] ✅ [#{self.class.name}] 파이프라인 완료 (#{total_time}ms)"

      context
    rescue AdExecute::Halt => e
      # halt!는 에러가 아닌 의도적 중단 신호 — 로깅 후 정상 종료
      Rails.logger.info "[Executor] 🛑 파이프라인 조기 종료: #{e.message}"
      context
    rescue StandardError => e
      Rails.logger.error "[Executor] ❌ 파이프라인 오류 발생: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      raise e
    end

    private

    def validate_pipeline!
      AdExecute::PipelineValidator.validate!(self.class, @action_classes)
    end

    protected

    # DSL 메서드: 단일 Action 클래스를 등록
    # @param [Class] action_class Action 상속 클래스
    # @param [Hash] options if/unless 조건부 실행 옵션
    def action(action_class, options = {})
      @action_classes << action_class
      
      @sequence_blocks << ->(context) do
        # 조건부 실행 체크 (if / unless)
        return if options[:if] && !evaluate_condition(options[:if], context)
        return if options[:unless] && evaluate_condition(options[:unless], context)

        start = Time.now
        begin
          action_class.new(context).execute
        ensure
          duration = ((Time.now - start) * 1000).round(2)
          Rails.logger.info "  └─ [Action] #{action_class.name.split('::').last} 처리 완료 (#{duration}ms)"
        end
      end
    end

    def evaluate_condition(condition, context)
      case condition
      when Proc
        condition.call(context)
      when Symbol
        context[condition].present?
      else
        condition
      end
    end
  end
end
