module AdExecute
  module Actions
    # Redis 캐시 기반 중복 참여 여부를 검사한다.
    # 중복 참여가 감지되면 ALREADY_PARTICIPATED 에러로 파이프라인을 중단한다.
    #
    # @context_requires [String] :click_key 클릭 키 (participate_start_v2_{click_key} 캐시 조회에 사용)
    #
    class CheckDuplicateParticipation < AdExecute::Action
      requires :request, :ad_hash, :click_key

      def execute
        click_key = context[:click_key]

        # 1. 중복 참여 검사 (Redis 캐시 기반)
        check_participate_v2(click_key)
      end

      private

      def check_participate_v2(click_key)
        key = format('participate_start_v2_%<click_key>s', click_key: click_key)
        # Rails.cache.exist? 에 옵션을 넘길 때는 namespace 만 분리해서 넘김
        if Rails.cache.exist?(key, namespace: 'api')
          raise AdisonErrors::BadRequest.new(Errors::ALREADY_PARTICIPATED)
        end
      end
    end
  end
end
