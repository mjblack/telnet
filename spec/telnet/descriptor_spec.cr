require "../spec_helper"

describe Telnet::Descriptor do
  describe "Client Descriptor" do
    it "should initialize a new client descriptor" do
      io = TCPSocket.tcp(Socket::Family::INET)
      descriptor = Telnet::Descriptor.new(io, :client)
      descriptor.should_not be_nil
    end

    it "should have typd of client" do
      io = TCPSocket.tcp(Socket::Family::INET)
      descriptor = Telnet::Descriptor.new(io, :client)
      descriptor.type.should eq(Telnet::Descriptor::Type::Client)
    end
  end

  describe "Server Descriptor" do
    io = TCPSocket.tcp(Socket::Family::INET)
    it "should initialize a new server descriptor" do
      descriptor = Telnet::Descriptor.new(io, :server)
      descriptor.should_not be_nil
    end

    it "should have type of server" do
      descriptor = Telnet::Descriptor.new(io, :server)
      descriptor.type.should eq(Telnet::Descriptor::Type::Server)
    end
  end
end
