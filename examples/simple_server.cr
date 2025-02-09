require "../src/telnet"

BIND_ADDR = "0.0.0.0"
BIND_PORT = 4000

class State
  @@instance : State?
  getter sessions = [] of Telnet::Session 
  @mutex : Mutex
  getter server : Telnet::Server

  def initialize
    @mutex = Mutex.new
    @server = Telnet::Server.new(BIND_ADDR, BIND_PORT)
  end
  
  def add_session(session : Telnet::Session)
    @mutex.synchronize do
      @sessions << session
      puts "Added session #{session.remote_address}"
    end
  end

  def self.add_session(session : Telnet::Session)
    instance.add_session(session)
  end
  
  def remove_session(session : Telnet::Session)
    @mutex.synchronize do
      @sessions.delete(session)
      puts "Removed session #{session.remote_address}"
    end
  end

  def self.remove_session(session : Telnet::Session)
    instance.remove_session(session)
  end

  def self.server
    instance.server
  end

  def self.sessions
    instance.sessions
  end

  def self.instance
    @@instance ||= State.new
  end
end

Signal::INT.trap do
  puts "Shutting down server"
  State.server.shutdown
  exit(0)
end

State.server.on_connect do |session|
  session.on_receive_data do |desc, data|
    str_data = String.new(data.to_unsafe)
    str = "Received data: #{str_data}"
    puts str
    desc.write(str.to_slice)
  end
  puts "session connected from #{session.remote_address}"
  State.add_session(session)
  do_echo = Telnet::Command.new_do(Telnet::Option::ECHO)
  session.write(do_echo)
  puts "Sent Do Echo: #{do_echo.inspect}"
  wont_echo = Telnet::Command.new_wont(Telnet::Option::ECHO)
  session.write(wont_echo)
  puts "Sent Wont Echo: #{wont_echo.inspect}"
  do_naws = Telnet::Command.new_do(Telnet::Option::NAWS)
  session.write(do_naws)
  puts "Sent Do NAWS: #{do_naws.inspect}"
end

State.server.on_disconnect do |session|
  puts "Client disconnected from #{session.remote_address}"
  State.remove_session(session)
end

Telnet::Parser.on_will_naws do |client|
  puts "Client will NAWS"
end

Telnet::Parser.on_subnegotiation_naws do |io, data|
  puts "Client sent NAWS: #{data}"
  # Convert the first two bytes to a 16-bit for width
  width = (data[0].to_u16 << 8) | data[1].to_u16
  # Convert the next two bytes to a 16-bit for height
  height = (data[2].to_u16 << 8) | data[3].to_u16
  puts "Client sent NAWS (W x H): #{width}x#{height}"
end

puts "Starting server on #{BIND_PORT}"
State.server.listen

puts "Starting sleep loop"
loop do
  Fiber.yield
end