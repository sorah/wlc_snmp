module WlcSnmp
  class Ap
    def initialize(name: , mac_address: nil, ethernet_mac_address: nil, location: nil, operational_status: nil, model: nil, serial: nil, ip_address: nil, type: nil, admin_status: nil)
      @name = name
      @mac_address = mac_address
      @ethernet_mac_address = ethernet_mac_address
      @location = location
      @operational_status = operational_status
      @model = model
      @serial = serial
      @ip_address = ip_address
      @type = type
      @admin_status = admin_status
    end

    attr_reader :name
    attr_reader :mac_address
    attr_reader :ethernet_mac_address
    attr_reader :location
    attr_reader :operational_status
    attr_reader :model
    attr_reader :serial
    attr_reader :ip_address
    attr_reader :type
    attr_reader :admin_status
  end
end
