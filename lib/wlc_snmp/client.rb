require 'snmp'

require 'wlc_snmp/client_data'
require 'wlc_snmp/ap'

module WlcSnmp
  class Client
    MIB_AIRESPACE_CLIENT_MAC = '1.3.6.1.4.1.14179.2.1.4.1.1'
    MIB_AIRESPACE_CLIENT_IP = '1.3.6.1.4.1.14179.2.1.4.1.2'

    MIB_AIRESPACE_AP_BASE_MAC = '1.3.6.1.4.1.14179.2.2.1.1.1'
    MIB_AIRESPACE_AP_NAME = '1.3.6.1.4.1.14179.2.2.1.1.3'
    MIB_AIRESPACE_AP_LOCATION = '1.3.6.1.4.1.14179.2.2.1.1.4'
    MIB_AIRESPACE_AP_OPER_STATUS = '1.3.6.1.4.1.14179.2.2.1.1.6'
    MIB_AIRESPACE_AP_MODEL = '1.3.6.1.4.1.14179.2.2.1.1.16'
    MIB_AIRESPACE_AP_SERIAL = '1.3.6.1.4.1.14179.2.2.1.1.17'
    MIB_AIRESPACE_AP_IP = '1.3.6.1.4.1.14179.2.2.1.1.19'
    MIB_AIRESPACE_AP_TYPE = '1.3.6.1.4.1.14179.2.2.1.1.22'
    MIB_AIRESPACE_AP_ETHENRET_MAC = '1.3.6.1.4.1.14179.2.2.1.1.33'
    MIB_AIRESPACE_AP_ADMIN_STATUS = '1.3.6.1.4.1.14179.2.2.1.1.37'

    MIB_LWAPP_AP_NAME = '1.3.6.1.4.1.9.9.513.1.1.1.1.5'
    MIB_LWAPP_AP_MAC = '1.3.6.1.4.1.9.9.513.1.1.1.1.2'

    MIB_LWAPP_CLIENT_MAC = '1.3.6.1.4.1.9.9.599.1.3.1.1.1'
    MIB_LWAPP_CLIENT_WLAN_PROFILE = '1.3.6.1.4.1.9.9.599.1.3.1.1.3'
    MIB_LWAPP_CLIENT_PROTOCOL = '1.3.6.1.4.1.9.9.599.1.3.1.1.6'
    MIB_LWAPP_CLIENT_AP_MAC = '1.3.6.1.4.1.9.9.599.1.3.1.1.8'
    MIB_LWAPP_CLIENT_IP = '1.3.6.1.4.1.9.9.599.1.3.1.1.10'
    MIB_LWAPP_CLIENT_UPTIME = '1.3.6.1.4.1.9.9.599.1.3.1.1.15'
    MIB_LWAPP_CLIENT_CURRENT_RATE = '1.3.6.1.4.1.9.9.599.1.3.1.1.17'
    MIB_LWAPP_CLIENT_RATE_SET = '1.3.6.1.4.1.9.9.599.1.3.1.1.18'
    MIB_LWAPP_CLIENT_USER = '1.3.6.1.4.1.9.9.599.1.3.1.1.27'
    MIB_LWAPP_CLIENT_SSID = '1.3.6.1.4.1.9.9.599.1.3.1.1.28'

    def initialize(host: , port: 161, community: )
      @host = host
      @port = port
      @community = community
    end

    def aps
      snmp_get_tree(
        mac_address: MIB_AIRESPACE_AP_BASE_MAC,
        name: MIB_AIRESPACE_AP_NAME,
        location: MIB_AIRESPACE_AP_LOCATION,
        operational_status: MIB_AIRESPACE_AP_OPER_STATUS,
        model: MIB_AIRESPACE_AP_MODEL,
        serial: MIB_AIRESPACE_AP_SERIAL,
        ip_address: MIB_AIRESPACE_AP_IP,
        type: MIB_AIRESPACE_AP_TYPE,
        ethernet_mac_address: MIB_AIRESPACE_AP_ETHENRET_MAC,
        admin_status: MIB_AIRESPACE_AP_ADMIN_STATUS,
      ).map do |data|
        Ap.new(
          name: data[:name].to_s,
          mac_address: unpack_mac(data[:mac_address]),
          location: data[:location]&.to_s,
          operational_status: data[:operational_status]&.to_i,
          model: data[:model]&.to_s,
          serial: data[:serial]&.to_s,
          ip_address: data[:ip_address]&.to_s,
          type: data[:ip_address],
          ethernet_mac_address: unpack_mac(data[:ethernet_mac_address]),
          admin_status: data[:admin_status]&.to_i,
        )
      end
    end

    def clients
      aps = aps().map{ |_| [_.mac_address, _] }.to_h

      airespace_clients = snmp_get_tree(ip: MIB_AIRESPACE_CLIENT_IP, mac: MIB_AIRESPACE_CLIENT_MAC).map do |data|
        [data[:ip].to_s, unpack_mac(data[:mac])]
      end.to_h

      snmp_get_tree(
        wlan_profile: MIB_LWAPP_CLIENT_WLAN_PROFILE,
        protocol: MIB_LWAPP_CLIENT_PROTOCOL,
        ap_mac: MIB_LWAPP_CLIENT_AP_MAC,
        ip: MIB_LWAPP_CLIENT_IP,
        uptime: MIB_LWAPP_CLIENT_UPTIME,
        data_rate: MIB_LWAPP_CLIENT_CURRENT_RATE,
        supported_data_rates: MIB_LWAPP_CLIENT_RATE_SET,
        user: MIB_LWAPP_CLIENT_USER,
        ssid: MIB_LWAPP_CLIENT_SSID,
      ).map do |data|
        ip = data[:ip].to_s.unpack("C*").map(&:to_s).join(?.)
        mac = airespace_clients[ip] ? airespace_clients[ip] : nil
        ap_mac = unpack_mac(data[:ap_mac])

        ClientData.new(
          mac_address: mac,
          ip_address: ip,
          ap: aps[ap_mac],
          wlan_profile: data[:wlan_profile].to_s,
          protocol: data[:protocol].to_i,
          ap_mac: ap_mac,
          uptime: data[:uptime].to_i,
          current_rate: data[:data_rate].to_s,
          supported_data_rates: data[:supported_data_rates].to_s.split(?,),
          user: data[:user]&.to_s,
          ssid: data[:ssid]&.to_s,
        )
      end
    end

    def snmp
      @snmp ||= SNMP::Manager.new(host: @host, port: @port, community: @community)
    end

    private

    def snmp_get_tree(attributes)
      variables = attributes.map do |key, oid|
        [key, snmp_walk(oid).map{|_| [_.name.index(oid).to_s, _] }.to_h]
      end

      variables.first[1].each_key.map do |index|
        variables.map do |key, vbs|
          [key, vbs[index]&.value]
        end.to_h
      end
    end

    def snmp_walk(tree)
      vbs = []
      pointer = tree
      begin
        list = snmp.get_bulk(0, 100, [pointer])
        list.varbind_list.each do |vb|
          unless vb.name.subtree_of?(tree)
            pointer = nil
            break
          end
          vbs.push vb
          pointer = vb.name
        end
      end while pointer
      vbs
    end

    def unpack_mac(mac)
      mac.unpack("C*").map{ |_| _.to_s(16).rjust(2,'0') }.join(?:)
    end
  end
end
