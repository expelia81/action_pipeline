module AdExecute
  module Concerns
    module LockManager
      # DSL 확장 메서드: with_lock(:ad_id, :uid) { ... }
      #
      # ⚠️  DSL 평가 시점 vs. 실행 시점 분리에 주의
      #   - 블록 안의 action 선언들은 initialize(define_sequence) 시점에 즉시 평가되어
      #     child_blocks 배열에 Proc으로 적재됩니다.
      #   - 실제 락 획득 및 child_blocks 실행은 execute(request) 호출 시점에 이루어집니다.
      #   - 블록 안에는 반드시 action() 선언만 사용하세요.
      def with_lock(*keys, &block)
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
          values   = keys.map { |k| context[k] || 'unknown' }
          # 원본 ParticipateService 포맷과 유사하게 맞춤 (pc_lock_{ad_id}_{uid})
          # context[:ad_hash][:id] 와 context[:request].uid 를 활용하는 것이 가장 정확하나,
          # DSL 유연성을 위해 전달받은 keys 기반으로 생성
          lock_key = "lock:#{values.join(':')}"

          Rails.logger.info "[LockManager] 🔒 [#{lock_key}] 획득 시도"
          
          lock_info = Rails.cache.lock(lock_key)
          if lock_info.blank?
            Rails.logger.error "[LockManager] ❌ [#{lock_key}] 획득 실패"
            raise AdisonErrors::BadRequest.new(Errors::ALREADY_PARTICIPATED, options: { log_message: "Failed to acquire lock: #{lock_key}" })
          end

          begin
            child_blocks.each { |child_proc| child_proc.call(context) }
          ensure
            Rails.cache.unlock(lock_key, lock_info[:val])
            Rails.logger.info "[LockManager] 🔓 [#{lock_key}] 해제"
          end
        end
      end
    end
  end
end
