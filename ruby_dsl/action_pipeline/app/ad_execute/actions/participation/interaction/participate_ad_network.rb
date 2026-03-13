module AdExecute
  module Actions
    # 외부 광고 네트워크(AdNetwork)에 참여 확인 요청을 보낸다.
    # ad_network_id가 없거나 check_participation_confirm 플래그가 false이면 건너뛴다.
    # 네트워크에서 종료(TERMINATED) 응답 시 광고를 비활성화하고 에러를 발생시킨다.
    # 성공 시 네트워크로부터 받은 redirect_url을 landing_url로 저장한다 (조건부).
    #
    # @context_requires [AdParticipateRequest] :request           참여 요청 DTO (advertising_id, client_ip 포함)
    # @context_requires [Hash]                :ad_hash            광고 정보 해시 (ad_network_id, ad_network_vars 포함)
    # @context_requires [Hash]                :publisher_app_hash 퍼블리셔 앱 정보 해시
    # @context_requires [String]              :click_key          클릭 키
    #
    # @context_provides [String] :landing_url AdNetwork에서 반환한 리다이렉트 URL (ad_network 연동 시에만 설정)
    class ParticipateAdNetwork < AdExecute::Action
      include Modules::NotificationManager

      requires :request, :ad_hash, :publisher_app_hash, :click_key
      provides :landing_url # ad_network 연동 시에만 조건부 설정

      def execute
        ad_hash = context[:ad_hash]
        return if ad_hash[:ad_network_id].to_i == 0

        ad_network_var_hash = AdisonCommonUtil.json_to_hash(ad_hash[:ad_network_vars])
        return unless ad_network_var_hash[:check_participation_confirm]

        request          = context[:request]
        publisher_app_hash = context[:publisher_app_hash]
        click_key        = context[:click_key]

        ad_network = AdNetwork.fetch_by_id(ad_hash[:ad_network_id])
        result, redirect_url, result_code = ad_network.participation_confirm(
          publisher_app_hash, click_key, request.advertising_id,
          ad_hash, ad_network_var_hash, request.client_ip, is_lat: request.is_lat
        )

        unless result
          case result_code
          when AdNetwork::ResultCode::TERMINATED
            disable_ad_network_ad(ad_hash)
            raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED)
          when AdNetwork::ResultCode::DUPLICATED
            raise AdisonErrors::BadRequest.new(Errors::AD_NETWORK_CAMPAIGN_ALREADY_COMPLETE)
          else
            raise AdisonErrors::BadRequest.new(Errors::AD_DISABLED)
          end
        end

        context[:landing_url] = redirect_url
      end

      private

      def disable_ad_network_ad(ad_hash)
        return unless ad_hash[:enable] == Ad::Enable::ON

        parent_ad_hash = Ad.fetch_ad_hash(ad_hash[:parent_id])
        Ad.off(parent_ad_hash[:id])
        AdNetworkAdOffHistory.create(
          ad_network_id: parent_ad_hash[:ad_network_id],
          parent_ad_id:  parent_ad_hash[:id],
          status:        AdNetworkAdOffHistory::Status::WAITING
        )
        send_mail_for_disable_ad(parent_ad_hash, nil, AdisonConstants::AdStatusChangeReason::AD_NETWORK_TERMINATED, async: true)
      end
    end
  end
end
