module Telnet
  class Client
    @descriptor : Descriptor

    def initialize
      # known command handlers default to ignore
      {% for key, val in Telnet::Option::OPTIONS %}
      {% for cmd in %w(do dont will wont) %}
      @parser.on_{{cmd.id}}_{{key.downcase.id}} =->{ nil }
      {% end %}
      {% end %}

      # subnegotiation handlers default to ignore
      {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
      on_subnegotiation_{{opt.downcase.id}} =->(_data : Array(UInt8)) { nil }
      {% end %}

      # @subnegotation_handler = ->(option : UInt8, _data : Array(UInt8)) { nil }
      @receive_data_handler = ->(_byte : Array(UInt8)) { nil }

      @ayt_handler = -> { nil }

      @descriptor = Descriptor.new_client
    end

    {% for key, val in Telnet::Option::OPTIONS %}
    {% for cmd in %w(do dont will wont) %}
    # See `Telnet::Descriptor#on_{{cmd.id}}_{{key.downcase.id}}`
    delegate on_{{cmd.id}}_{{key.downcase.id}}, to: @descriptor
    {% end %}
    {% end %}

    {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
    # See `Telnet::Descriptor#on_subnegotiation_{{opt.downcase.id}}`
    delegate on_subnegotiation_{{opt.downcase.id}}, to: @descriptor
    {% end %}

    # See `Telnet::Descriptor#on_receive_data`
    delegate on_receive_data, to: @descriptor

    # See `Telnet::Descriptor#on_unknown_command`
    delegate on_unknown_command, to: @descriptor

    # See `Telnet::Descriptor#on_ayt`
    delegate on_ayt, to: @@descriptor

    # See `Descriptor#close`
    delegate close, to: @descriptor

    # See `Descriptor#read`
    delegate read, to: @descriptor

    # See `Descriptor#write`
    delegate write, to: @descriptor

    # See `Descriptor#remote_address`
    delegate remote_address, to: @descriptor

    # See `Descriptor#local_address`
    delegate local_address, to: @descriptor

    # See `Descriptor#connect`
    delegate connect, to: @descriptor
  end
end
