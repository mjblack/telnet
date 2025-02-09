module Telnet
  class Session
    @descriptor : Descriptor
    @parser : Parser
    getter remote_address : String

    def initialize(@descriptor : Descriptor)
      @parser = Parser.new(@descriptor)
      @remote_address = @descriptor.remote_address.to_s

      # known command handlers default to ignore
      {% for key, val in Telnet::Option::OPTIONS %}
      {% for cmd in %w(do dont will wont) %}
      on_{{cmd.id}}_{{key.downcase.id}} =->{ nil }
      {% end %}
      {% end %}

      # subnegotiation handlers default to ignore
      {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
      on_subnegotiation_{{opt.downcase.id}} =->(_data : Array(UInt8)) { nil }
      {% end %}
    end

    {% for key, val in Telnet::Option::OPTIONS %}
    {% for cmd in %w(do dont will wont) %}
    # See `Telnet::Parser#on_{{cmd.id}}_{{key.downcase.id}}`
    delegate on_{{cmd.id}}_{{key.downcase.id}}, to: @parser
    {% end %}
    {% end %}

    def start
      loop do
        Fiber.yield
        begin
          if @descriptor.closed?
            break
          end
          if @descriptor.peek.empty?
            @descriptor.close
            break
          end
          slice = Bytes.new(Telnet::MAX_BUFFER_SIZE)
          num = @descriptor.read(slice)
          if num > 0
            @parser.parse(slice)
          end
        rescue e : IO::Error
          # Client bas been disconnected so we call close on socket and break loop.
          @descriptor.close
          break
        end
      end
    end

    def closed?
      @descriptor.closed?
    end

    def close
      @descriptor.close
    end

    {% for key, val in Telnet::Option::OPTIONS %}
    {% for cmd in %w(do dont will wont) %}
    # See `Telnet::Parser#on_{{cmd.id}}_{{key.downcase.id}}`
    delegate on_{{cmd.id}}_{{key.downcase.id}}, to: @parser
    {% end %}
    {% end %}

    {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
    # See `Telnet::Parser#on_subnegotiation_{{opt.downcase.id}}`
    delegate on_subnegotiation_{{opt.downcase.id}}, to: @parser
    {% end %}

    # See `Telnet::Parser#on_receive_data`
    # delegate on_receive_data, to: @parser
    def on_receive_data(&block : Proc(Descriptor, Array(UInt8), Nil))
      @parser.on_receive_data(&block)
    end

    # See `Telnet::Parser#on_unknown_command`
    delegate on_unknown_command, to: @parser

    # See `Telnet::Parser#on_ayt`
    delegate on_ayt, to: @parser

    # We pass everything else to `@descriptor`
    forward_missing_to @descriptor
  end
end
