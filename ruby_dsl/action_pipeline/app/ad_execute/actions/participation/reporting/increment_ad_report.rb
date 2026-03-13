module AdExecute
  module Actions
    # 광고 실적(AdReport)의 참여 카운터를 Redis에서 증가시킨다.
    # AdReport 증가는 일일 예산(CAP) 차감을 겸하므로, 반드시 with_lock 블록 내부에서 실행해야 한다.
    # with_lock 밖에서 실행 시 락 해제 후 재진입한 요청이 예산 초과 집행을 유발한다.
    # ad_hash의 linked_ad 배열 파싱 실패 시 단일 ad_id 배열로 폴백하여 장애를 방지한다.
    #
    # @note with_transaction 밖, with_lock 안에서 실행해야 한다 (Redis는 DB 트랜잭션 롤백 대상 아님)
    #
    # @context_requires [Hash] :ad_hash 광고 정보 해시 (id, linked_ad 배열 파싱에 사용)
    class IncrementAdReport < AdExecute::Action
      requires :ad_hash

      def execute
        ad_hash = context[:ad_hash]
        ad_id_array = begin
                        Ad.ad_id_array(ad_hash)
                      rescue StandardError => e
                        log_error "Failed to parse linked_ad", { ad_id: ad_hash[:id], error: e.message }
                        [ad_hash[:id]]
                      end
        AdReport.increment_participate(ad_id_array, Time.now)
      end
    end
  end
end
