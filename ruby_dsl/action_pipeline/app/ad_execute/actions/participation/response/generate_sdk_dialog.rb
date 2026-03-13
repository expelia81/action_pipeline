module AdExecute
  module Actions
    # SDK 팝업(다이얼로그) 표시에 필요한 데이터를 생성한다.
    # 광고 정보, 랜딩 URL, 퍼블리셔 앱 정보, OS 버전을 조합하여
    # SDK가 팝업을 렌더링할 수 있는 구조체(sdk_dialog)를 컨텍스트에 저장한다.
    #
    # @context_requires [AdParticipateRequest] :request           참여 요청 DTO (os_ver 포함 가능)
    # @context_requires [Hash]                :ad_hash            광고 정보 해시
    # @context_requires [Hash]                :publisher_app_hash 퍼블리셔 앱 정보 해시
    # @context_requires [String]              :landing_url        최종 랜딩 URL
    #
    # @context_provides [Hash] :sdk_dialog SDK 팝업 렌더링 데이터
    class GenerateSdkDialog < AdExecute::Action
      include Modules::SdkDialogManager

      requires :request, :ad_hash, :publisher_app_hash, :landing_url
      provides :sdk_dialog

      def execute
        request            = context[:request]
        ad_hash            = context[:ad_hash]
        landing_url        = context[:landing_url]
        publisher_app_hash = context[:publisher_app_hash]
        
        os_ver = request.os_ver

        sdk_dialog = participate_sdk_dialog(ad_hash, landing_url, publisher_app_hash, os_ver)
        
        context[:sdk_dialog] = sdk_dialog
      end
    end
  end
end
