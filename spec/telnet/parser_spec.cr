require "spec"
require "../spec_helper"

describe Telnet::Parser do
  chan = Channel(String).new(10)
  io = TCPSocket.tcp(Socket::Family::INET)
  descriptor = Telnet::Descriptor.new(io, :client)
  parser = Telnet::Parser.new(descriptor)

  parser.on_will_echo do
    chan.send("WILL ECHO")
  end

  parser.on_wont_echo do
    chan.send("WONT ECHO")
  end

  parser.on_do_echo do
    chan.send("DO ECHO")
  end

  parser.on_dont_echo do
    chan.send("DONT ECHO")
  end

  parser.on_ayt do
    chan.send("AYT")
  end

  parser.on_subnegotiation_ttype do |_, data|
    if byte = data.shift
      if byte == Telnet::Command::IS
        ttype = String.new(data.to_unsafe)
        chan.send("TTYPE #{ttype}")
      else
        chan.send("TTYPE Unknown")
      end
    else
      chan.send("TTYPE Unknown")
    end
  end

  it "parses a WILL ECHO negotiation command" do
    command = "\xff\xfb\x01".to_slice # IAC WILL ECHO
    parser.parse(command)
    result = chan.receive
    result.should eq("WILL ECHO")
  end

  it "parses a WONT ECHO negotiation command" do
    command = "\xff\xfc\x01".to_slice # IAC WONT ECHO
    parser.parse(command)
    result = chan.receive
    result.should eq("WONT ECHO")
  end

  it "parses a DO ECHO negotiation command" do
    command = "\xff\xfd\x01".to_slice # IAC DO ECHO
    parser.parse(command)
    result = chan.receive
    result.should eq("DO ECHO")
  end

  it "parses a DONT ECHO negotiation command" do
    command = "\xff\xfe\x01".to_slice # IAC DONT ECHO
    parser.parse(command)
    result = chan.receive
    result.should eq("DONT ECHO")
  end

  it "parses a TTYPE subnegotiation command" do
    command = "\xff\xfa\x18\x00VT100\xff\xf0\n\r".to_slice # IAC SB TTYPE IS vt100 IAC SE
    parser.parse(command)
    result = chan.receive
    result.should eq("TTYPE VT100")
  end

  it "parses an AYT command" do
    command = "\xff\xf6".to_slice # IAC AYT
    parser.parse(command)
    result = chan.receive
    result.should eq("AYT")
  end
end
