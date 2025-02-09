module Telnet
  module Command
    extend self

    IS   = 0_u8
    SEND = 1_u8

    # :nodoc:
    COMMANDS = {
      "IAC"   => 255_u8, # interpret as command
      "DONT"  => 254_u8, # you are not to use option
      "DO"    => 253_u8, # please, you use option
      "WONT"  => 252_u8, # I won"t use option
      "WILL"  => 251_u8, # I will use option
      "SB"    => 250_u8, # interpret as subnegotiation
      "GA"    => 249_u8, # you may reverse the line
      "EL"    => 248_u8, # erase the current line
      "EC"    => 247_u8, # erase the current character
      "AYT"   => 246_u8, # are you there
      "AO"    => 245_u8, # abort output--but let prog finish
      "IP"    => 244_u8, # interrupt process--permanently
      "BREAK" => 243_u8, # break
      "DM"    => 242_u8, # data mark--for connect. cleaning
      "NOP"   => 241_u8, # nop
      "SE"    => 240_u8, # end sub negotiation
      "EOR"   => 239_u8, # end of record (transparent mode)
      "ABORT" => 238_u8, # Abort process
      "SUSP"  => 237_u8, # Suspend process
      "EOF"   => 236_u8, # End of file
    }

    {% for cmd in COMMANDS %}
    {{cmd.upcase.id}} = {{COMMANDS[cmd]}}
    {% end %}

    {% for cmd in %w(do dont will wont) %}
    def new_{{cmd.downcase.id}}(opt : UInt8) : Slice(UInt8)
      a = [IAC, COMMANDS[{{cmd.upcase.id.stringify}}], opt]
      Slice(UInt8).new(a.to_unsafe, a.size)
    end
    {% end %}

    def new_subneg(opt : UInt8, data : Array(UInt8)) : Slice(UInt8)
      a = [IAC, SB, opt] + data + [IAC, SE]
      Slice(UInt8).new(a.to_unsafe, a.size)
    end

    def new_subneg_is(opt : UInt8, data : Array(UInt8)) : Slice(UInt8)
      a = [IAC, SB, opt, IS] + data + [IAC, SE]
      Slice(UInt8).new(a.to_unsafe, a.size)
    end

    def new_subneg_send(opt : UInt8, data : Array(UInt8)) : Slice(UInt8)
      a = [IAC, SB, opt, SEND] + data + [IAC, SE]
      Slice(UInt8).new(a.to_unsafe, a.size)
    end

    def find_command(byte : UInt8) : String | Nil
      COMMANDS.key_for?(byte)
    end

    def find_command(command : String) : UInt8 | Nil
      COMMANDS[command.upcase]?
    end
  end
end
