module AdExecute
  # 광고 참여에 필요한 모든 정보를 담고 있는 데이터 전송 객체 (공통 페이로드)
  class AdParticipateRequest
    attr_reader :ad_type, :uid, :ad_id, :advertising_id, 
                :publisher_app_id, :publisher_app_hash, 
                :client_ip, :os_ver, :from,
                :sdk_ver, :is_lat,
                :aot_source, :aot_medium, :aot_sub_params,
                :referenced_npcb_p_token,
                :placement_id, :request_id, :action_id, :inventory,
                :tab_slug, :tag_slug,
                :review_report_id, :review_report_status, :review_report_reason,
                :review_report_created_at, :review_report_updated_at

    def initialize(ad_type:, uid:, ad_id:, advertising_id: nil, 
                   publisher_app_id: nil, publisher_app_hash: nil, 
                   client_ip: nil, os_ver: nil, from: nil,
                   sdk_ver: nil, is_lat: nil,
                   aot_source: nil, aot_medium: nil, aot_sub_params: nil,
                   referenced_npcb_p_token: nil,
                   placement_id: nil, request_id: nil, action_id: nil, inventory: nil,
                   tab_slug: nil, tag_slug: nil,
                   review_report_id: nil, review_report_status: nil, review_report_reason: nil,
                   review_report_created_at: nil, review_report_updated_at: nil)
      @ad_type = ad_type
      @uid = uid
      @ad_id = ad_id
      @advertising_id = advertising_id
      @publisher_app_id = publisher_app_id
      @publisher_app_hash = publisher_app_hash
      @client_ip = client_ip
      @os_ver = os_ver
      @from = from
      @sdk_ver = sdk_ver
      @is_lat = is_lat
      @aot_source = aot_source
      @aot_medium = aot_medium
      @aot_sub_params = aot_sub_params
      @referenced_npcb_p_token = referenced_npcb_p_token
      @placement_id = placement_id
      @request_id = request_id
      @action_id = action_id
      @inventory = inventory
      @tab_slug = tab_slug
      @tag_slug = tag_slug
      @review_report_id = review_report_id
      @review_report_status = review_report_status
      @review_report_reason = review_report_reason
      @review_report_created_at = review_report_created_at
      @review_report_updated_at = review_report_updated_at
    end
  end
end
