module Telnet
  # The `Parser` class is responsible for parsing input strings and extracting relevant data.
  #
  # ## Usage
  #
  # ```
  # parser = Parser.new
  # result = parser.parse("input string")
  # puts result
  # ```
  #
  # The `parse` method takes an input string and returns the parsed result.
  #
  # ## Example
  #
  # ```
  # parser = Parser.new
  # input = "example input"
  # parsed_data = parser.parse(input)
  # puts parsed_data
  # ```
  #
  # In this example, the `Parser` instance is created, and the `parse` method is called with an input string.
  # The parsed data is then printed to the console.
  #
  # ## Telnet Commands and Subnegotiations
  # The `Parser` class handles Telnet commands and subnegotiations. There can be a default handler for each command
  # and subnegotiations. The default handler can be overridden at the instance level.
  #
  # You can set a callback at the class level by doing the following:
  # ```
  # Parser.on_do_echo do
  #   io.write(Telnet::Command.new_will(Telnet::Option::ECHO))
  # end
  # ```
  # You can set a callback at the instance level by doing the following:
  # ```
  # parser = Parser.new
  # parser.on_do_echo do
  #   io.write(Telnet::Command.new_will(Telnet::Option::ECHO))
  # end
  # ```
  # You can set a similar callback for subnegotiations at the class level or instance level.
  # An example of setting a subnegotiation callback at the instance level for the NAWS (Negotiate About Window Size) option
  # is shown below for both the command and subnegotiation.
  # ```
  # parser = Parser.new
  # parser.on_will_naws do
  #   io.write(Telnet::Command.new_subneg(Telnet::Option::NAWS, data))
  # end
  #
  # # Client sends IAC SB NAWS <data> <data> <data> <data> IAC SE
  # parser.on_subnegotiation_naws do |data|
  #   # Convert the first two bytes to a 16-bit for width
  #   width = (naws[0].to_u16 << 8) | naws[1].to_u16
  #   # Convert the next two bytes to a 16-bit for height
  #   height = (naws[2].to_u16 << 8) | naws[3].to_u16
  # end
  # ```
  class Parser
    # Class level handlers are default. They can be overridden by instance level handlers.
    @@handlers = {} of String => Proc(Descriptor, Nil)
    @@subnegotation_handlers = {} of String => Proc(Descriptor, Array(UInt8), Nil)
    @@ayt_handler : Proc(Descriptor, Nil)
    @@unknown_command_handler : Proc(Descriptor, UInt8, UInt8, Nil)
    @@receive_data_handler : Proc(Descriptor, Array(UInt8), Nil)

    {% for key, val in Telnet::Option::OPTIONS %}
    {% for cmd in %w(do dont will wont) %}
    # :nodoc:
    @@handlers["{{cmd.id}}_{{key.downcase.id}}"] =->(_desc : Descriptor) { nil }
    {% end %}
    {% end %}

    {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
    # :nodoc:
    @@subnegotation_handlers[{{opt.downcase}}] =->(_desc : Descriptor, _data : Array(UInt8)) { nil }
    {% end %}

    # :nodoc:
    @@ayt_handler = ->(_desc : Descriptor) { nil }

    # :nodoc:
    @@unknown_command_handler = ->(_desc : Descriptor, _command : UInt8, _option : UInt8) { nil }

    # :nodoc:
    @@receive_data_handler = ->(_desc : Descriptor, _byte : Array(UInt8)) { nil }

    # Enable character mode. When enabled the parser will send individual characters to the receive_data_handler.
    # When it is disabled the parser will send the entire buffer to the receive_data_handler after processing
    # telnet protocol data.
    property? charmode : Bool = false
    @buffer = [] of UInt8
    # Store characters when charmode is disabled
    @buffer2 = [] of UInt8
    # command handlers
    # Proc takes in the option byte for processing the command. The return expects the byte to be on return.
    @handlers = {} of String => Proc(Descriptor, Nil)
    # subnegotiation handler
    # Proc takes in the option and data bytes for processing. The return expects the option byte to be on return.
    @subnegotation_handlers = {} of String => Proc(Descriptor, Array(UInt8), Nil)
    # unknown command handler
    # Proc takes in the command and option byte for processing the command. The return expects the option
    # byte to be on return.
    @unknown_command_handler : Proc(Descriptor, UInt8, UInt8, Nil)

    # Are You There (AYT) handler
    @ayt_handler : Proc(Descriptor, Nil)

    # Receive data handler for the descriptor. The
    @receive_data_handler : Proc(Descriptor, Array(UInt8), Nil)

    # The descriptor
    @io : Descriptor

    def initialize(@io : Descriptor)
      # unknown command handler default is to ignore
      @unknown_command_handler = ->(_desc : Descriptor, _command : UInt8, option : UInt8) { @@unknown_command_handler.call(_desc, _command, option) }

      # known command handlers default to ignore
      {% for key, val in Telnet::Option::OPTIONS %}
      {% for cmd in %w(do dont will wont) %}
      @handlers["{{cmd.id}}_{{key.downcase.id}}"] =->(_desc : Descriptor){ @@handlers["{{cmd.id}}_{{key.downcase.id}}"].call(_desc) if @@handlers.has_key?("{{cmd.id}}_{{key.downcase.id}}") }
      {% end %}
      {% end %}

      # subnegotiation handlers default to ignore
      {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
      @subnegotation_handlers[{{opt.downcase}}] =->(_desc : Descriptor, _data : Array(UInt8)) { @@subnegotation_handlers[{{opt.downcase}}].call(_desc, _data) if @@subnegotation_handlers.has_key?({{opt.downcase}}) }
      {% end %}

      @receive_data_handler = ->(_desc : Descriptor, _byte : Array(UInt8)) { @@receive_data_handler.call(_desc, _byte) }

      @ayt_handler = ->(_desc : Descriptor) { @@ayt_handler.call(_desc) }
    end

    # Appends the data to the end of the buffer and then calls to process the buffer.
    def parse(data : Array(UInt8))
      @buffer.concat(data)
      process_buffer
    end

    # Converts the data to an array of UInt8 and calls `#parse`.
    def parse(data : Slice(UInt8))
      parse(data.to_a)
    end

    def on_receive_data(&block : Proc(Descriptor, Array(UInt8), Nil))
      @receive_data_handler = block
    end

    def on_unknown_command(&block : Proc(Descriptor, UInt8, UInt8, Nil))
      @unknown_command_handler = block
    end

    {% for key, val in Telnet::Option::OPTIONS %}
    {% for cmd in %w(do dont will wont) %}
    # Set the callback to be called when a {{cmd.id}} {{key}} command is received at the instance level.
    def on_{{cmd.id}}_{{key.downcase.id}}(&block : Proc(Descriptor, Nil))
      @handlers["{{cmd.id}}_{{key.downcase.id}}"] = block
    end

    # Set the callback to be called when a {{cmd.id}} {{key}} command is received at the class level and will be default for all instances.
    # The callback can be overridden at the instance level.
    def self.on_{{cmd.id}}_{{key.downcase.id}}(&block : Proc(Descriptor, Nil))
      @@handlers["{{cmd.id}}_{{key.downcase.id}}"] = block
    end
    {% end %}
    {% end %}

    {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
    # Set the callback to be called when a subnegotiation for the {{opt}} option is received at the instance level.
    def on_subnegotiation_{{opt.downcase.id}}(&block : Proc(Descriptor, Array(UInt8), Nil))
      @subnegotation_handlers[{{opt.downcase}}] = block
    end

    # Set the callback to be called when a subnegotiation for the {{opt}} option is received at the class level and will be default for all instances.
    # The callback can be overridden at the instance level.
    def self.on_subnegotiation_{{opt.downcase.id}}(&block : Proc(Descriptor, Array(UInt8), Nil))
      @@subnegotation_handlers[{{opt.downcase}}] = block
    end
    {% end %}

    # Set the callback to be called when an AYT (Are You There) command is received at the instance level.
    def on_ayt(&block : Proc(Descriptor, Nil))
      @ayt_handler = block
    end

    # Set the callback to be called when an AYT (Are You There) command is received at the class level and will be default for all instances.
    # The callback can be overridden at the instance level.
    def self.on_ayt(&block : Proc(Descriptor, Nil))
      @@ayt_handler = block
    end

    # Processes data in the buffer and sends it to the appropriate handler for the type of data.
    # Types of data are commands, subnegotiations, and regular data.
    private def process_buffer
      while @buffer.size > 0
        byte = @buffer.shift
        case byte
        when Telnet::Command::IAC
          if @buffer.size == 1
            next_byte = @buffer.shift
            # Received `IAC IAC` which is an escaped IAC byte.
            if next_byte == Telnet::Command::IAC
              send_to_buffer([next_byte])
            elsif next_byte == Telnet::Command::AYT
              handle_ayt
              next
            else
              @buffer.unshift(next_byte)
            end
          end
          if @buffer.size >= 2
            handle_command
          else
            # If buffer is empty then we have an incomplete command. We need to wait for more data.
            @buffer.unshift(byte)
            break
          end
        else
          # Regular data
          send_to_buffer([byte])
        end
      end
    end

    # Sends data to the receive_data_handler. If charmode is enabled, data is sent one byte at a time. If charmode is disabled,
    # data is stored until a newline character is received. The stored data is then sent to the receive_data_handler.
    private def send_to_buffer(data : Array(UInt8))
      data.delete(Telnet::LF)
      data.delete(Telnet::NULL)
      return if data.empty?
      if charmode?
        @receive_data_handler.call(@io, data)
      else
        @buffer2.concat(data)
        if @buffer2.includes?(Telnet::CR)
          @receive_data_handler.call(@io, @buffer2)
          @buffer2.clear
        end
      end
    end

    # Handles telnet commands.
    private def handle_command
      return if @buffer.size < 2
      command = @buffer.shift
      option = @buffer.shift
      case command
      when Telnet::Command::DO
        handle_do(option)
      when Telnet::Command::DONT
        handle_dont(option)
      when Telnet::Command::WILL
        handle_will(option)
      when Telnet::Command::WONT
        handle_wont(option)
      when Telnet::Command::SB
        handle_subnegotiation(option)
      when Telnet::Command::IAC
        send_to_buffer([Telnet::Command::IAC])
      when Telnet::Command::AYT
        handle_ayt
      else
        handle_unknown_command(command, option)
      end
    end

    {% for cmd in %w(will wont do dont) %}
      # Handles {{cmd}} commands.
      private def handle_{{cmd.id}}(option : UInt8)
        opt_name = Telnet::Option.find_option(option)
        if handler = @handlers["{{cmd.downcase.id}}_#{opt_name.downcase}"]
          handler.call(@io)
        end
      end
    {% end %}

    # Handles subnegotiation commands.
    private def handle_subnegotiation(option : UInt8)
      data = [] of UInt8
      while @buffer.size > 0
        byte = @buffer.shift
        if byte == Telnet::Command::SE # end of subnegotiation
          break
        end
        if byte == Telnet::Command::IAC # skip IAC byte
          next
        end
        data << byte
      end
      {% begin %}
      case option
      {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
      when Telnet::Option::{{opt.id}}
        handle_subnegotiation_{{opt.downcase.id}}(data)
      {% end %}
      end
      {% end %}
    end

    # Handles the AYT (Are You There) command.
    private def handle_ayt
      @ayt_handler.call(@io)
    end

    {% for opt in %w(NAWS TTYPE TSPEED LFLOW LINEMODE XDISPLOC AUTHENTICATION ENCRYPT NEWENVIRON COMPORT EXTASCII) %}
    # Handles subnegotiation for the {{opt}} option.
    private def handle_subnegotiation_{{opt.downcase.id}}(data : Array(UInt8))
      opt_name = Telnet::Option::OPTIONS.key_for(Telnet::Option::OPTIONS[{{opt.upcase}}])
      @subnegotation_handlers[opt_name.downcase].call(@io, data)
    end
    {% end %}

    # Handles unknown any commands.
    private def handle_unknown_command(command : UInt8, option : UInt8)
      @unknown_command_handler.call(@io, command, option)
    end
  end
end
