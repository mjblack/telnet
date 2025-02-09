module Telnet
  # Descriptor class wraps an IO object and provides a parser for telnet protocol through the Parser class.
  # It also contains the IO loop for reading data from the socket when it is a client type. The IO loop is
  # started in its own fiber when the connection is established.
  class Descriptor
    CONNECT_TIMEOUT = 5

    enum Type
      # Connection is from client to a server
      Client
      # Connection is from an external client connecting to the server
      Server
    end

    @io : TCPSocket
    getter type : Type
    @in_buf : Channel(UInt8)

    def initialize(@io : TCPSocket, @type : Type)
      @in_buf = Channel(UInt8).new(Telnet::MAX_BUFFER_SIZE)
    end

    def self.new_client
      io = Socket.tcp(Socket::Family::INET)
      desc = new(io, :client)
      desc
    end

    def connect(address : String, port : Int32) : Bool
      begin
        @io.connect(address, port, CONNECT_TIMEOUT)
      rescue e : Socket::ConnectError
        return false
      end
      spawn(name: "Telnet Descriptor") { start }
      true
    end

    def start
      loop do
        begin
          slice = Bytes.new(MAX_BUFFER_SIZE)
          num = @io.read(slice)
          if num > 0
            @parser.parse(slice)
          end
        rescue e
          # Client bas been disconnected so we break loop.
          @io.close
          break
        end
      end
    end

    def close
      @io.close
    end

    def finalize
      close
    end

    # Write a byte to the socket
    def write(data : UInt8)
      @io.write_byte(data)
    end

    # Write an array of bytes to the socket
    def write(data : Array(UInt8))
      slice = Slice(UInt8).new(data.to_unsafe, data.size)
      @io.write(slice)
    end

    # Forward missing methods to the TCPSocket object
    forward_missing_to @io
  end
end
