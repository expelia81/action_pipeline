module AdExecute
  module Concerns
    module TransactionManager
      # DSL 확장 메서드: with_transaction { ... }
      #
      # ⚠️  DSL 평가 시점 vs. 실행 시점 분리에 주의 (with_lock과 동일한 메커니즘)
      #   - 블록 안의 action 선언들은 initialize(define_sequence) 시점에 평가됩니다.
      #   - 트랜잭션 BEGIN/COMMIT/ROLLBACK은 execute(request) 시점에 실행됩니다.
      #   - 블록 안에는 반드시 action() 선언만 사용하세요.
      #   - DB 작업이 아닌 Redis/캐시 작업은 이 블록 밖에 배치해야 합니다.
      def with_transaction(&block)
        original_blocks  = @sequence_blocks
        original_classes = @action_classes
        child_blocks  = []
        child_classes = []

        @sequence_blocks = child_blocks
        @action_classes  = child_classes
        instance_eval(&block)
        @sequence_blocks = original_blocks
        @action_classes  = original_classes

        # 중첩 Action들도 PipelineValidator 검증 대상에 포함
        original_classes.concat(child_classes)

        @sequence_blocks << ->(context) do
          ActiveRecord::Base.transaction do
            child_blocks.each { |child_proc| child_proc.call(context) }
          end
        end
      end
    end
  end
end
