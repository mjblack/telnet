module Telnet
  class Server
    class BadSocketError < Exception; end

    @sock : TCPServer
    getter bind_address : String
    getter bind_port : Int32
    property backlog : Int32
    getter sessions = [] of Session
    @sessions_mutex : Mutex

    # callbacks for user code to handle new connections
    # Proc takes in the client descriptor for processing. The return expects nil.
    @on_connect : Proc(Session, Nil)
    # callbacks for user code to handle disconnections
    # Proc takes in the client descriptor for processing. The return expects nil.
    @on_disconnect : Proc(Session, Nil)

    # command handlers
    # Proc takes in the option byte for processing the command. The return expects the byte to be on return.
    @handlers = {} of String => Proc(Nil)
    # subnegotiation handler
    # Proc takes in the option and data bytes for processing. The return expects the option byte to be on return.
    @subnegotation_handlers = {} of String => Proc(Array(UInt8), Nil)
    # unknown command handler
    # Proc takes in the command and option byte for processing the command. The return expects the option
    # byte to be on return.
    @unknown_command_handler : Proc(UInt8, UInt8, Nil)

    # Create a new Telnet server instance.
    # `@bind_address` is the IP address to bind the server to.
    # `@bind_port` is the port to bind the server to.
    #
    # ```
    # server = Telnet::Server.new("0.0.0.0", 9099)
    # ```
    def initialize(@bind_address : String, @bind_port : Int32, @backlog : Int32 = Socket::SOMAXCONN)
      @sock = TCPServer.new(host: @bind_address, port: @bind_port, backlog: @backlog)
      @on_connect = ->(_session : Session) { nil }
      @on_disconnect = ->(_session : Session) { nil }
      @unknown_command_handler = ->(_cmd : UInt8, _opt : UInt8) { nil }
      @sessions_mutex = Mutex.new
    end

    # Create a new Telnet server instance.
    # `bind_address` defaults to `127.0.0.1`
    # `port` defaults to `23`
    #
    # ```
    # server = Telnet::Server.new
    # ```
    # or
    # ```
    # server = Telnet::Server.new(9099)
    # ```
    def self.new(port : Int32 = 23)
      new("127.0.0.1", port)
    end

    # Set the callback to be called when a descriptor connects.
    # The callback will be passed the descriptor descriptor.
    # The callback yields the descriptor.
    #
    # ```
    # server.on_connect do |descriptor|
    #  puts "descriptor connected from #{descriptor.remote_address}"
    # end
    def on_connect(&block : Proc(Session, Nil))
      @on_connect = block
    end

    # Set the callback to be called when a descriptor disconnects.
    # The callback will be passed the descriptor.
    # The callback yields the descriptor.
    #
    # ```
    # server.on_disconnect do |descriptor|
    #   puts "descriptor disconnected from #{descriptor.remote_address}"
    # end
    # ```
    def on_disconnect(&block : Proc(Session, Nil))
      @on_disconnect = block
    end

    # :nodoc:
    private def add_session(session : Session)
      @sessions_mutex.synchronize do
        @sessions << session
      end
      @on_connect.call(session)
    end

    # :nodoc:
    private def remove_session(session : Session)
      @sessions_mutex.synchronize do
        @sessions.delete(session)
      end
      @on_disconnect.call(session)
    end

    # Handle a descriptor connection.
    # This method is called when a descriptor connects to the server.
    # The descriptor is passed as an argument.
    private def handle_session(io : TCPSocket)
      descriptor = Descriptor.new(io, :server)
      session = Session.new(descriptor)
      spawn(name: "Telnet Session") { session.start }
      add_session(session)
    end

    # Start the IO loop for the server.
    private def io_loop
      spawn(name: "Telnet Server IO Loop") do
        loop do
          @sessions.each do |session|
            begin
              if session.closed?
                remove_session(session)
              end
            rescue
              session.close
              remove_session(session)
            end
          end
          # Fiber.yield
          sleep 0.001.seconds
        end
      end
    end

    # Start the listener loop for the server.
    private def listener_loop
      spawn(name: "Telnet Server: #{@bind_address}:#{@bind_port}") do
        loop do
          begin
            if io = @sock.accept?
              handle_session(io)
            else
              raise BadSocketError.new("Failed to accept connection")
            end
          rescue
          end
        end
      end
    end

    # Start the io loop and then start server to listen for incoming connections.
    #
    # ```
    # server = Telnet::Server.new
    # server.listen
    # ```
    def listen : Nil
      io_loop
      listener_loop
    end

    # Close the server socket.
    def shutdown
      @sock.close
    end

    macro method_missing(call)
      @sock.{{call.name.id}}({{call.args.splat}})
    end
  end
end
