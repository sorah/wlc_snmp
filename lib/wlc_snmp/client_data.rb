module WlcSnmp
  class ClientData
    def initialize(ip_address: , mac_address: nil, wlan_profile: nil, protocol: nil, ap_mac: nil, uptime: nil, current_rate: nil, supported_data_rates: nil, user: nil, ssid: nil, ap: nil)
      @ip_address = ip_address
      @mac_address = mac_address
      @wlan_profile = wlan_profile
      @protocol = protocol
      @ap_mac = ap_mac
      @uptime = uptime
      @current_rate = current_rate
      @supported_data_rates = supported_data_rates
      @user = user
      @ssid = ssid
      @ap = ap
    end

    attr_reader :ip_address
    attr_reader :mac_address
    attr_reader :wlan_profile
    attr_reader :protocol
    attr_reader :ap_mac
    attr_reader :uptime
    attr_reader :current_rate
    attr_reader :supported_data_rates
    attr_reader :user
    attr_reader :ssid
    attr_reader :ap
  end
end
