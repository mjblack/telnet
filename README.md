# telnet

Telnet shard that provides server and client classes. It provides a parser class that handles telnet events with callbacks.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     telnet:
       github: mjblack/telnet
   ```

2. Run `shards install`

## Usage

Please see [examples/simple_server.cr](https://github.com/mjblack/telnet/blob/master/examples/simple_server.cr) for a more detailed example that showcases telnet command and subnegotiation handling.

```crystal
require "telnet"

server = Telnet::Server.new("0.0.0.0", 23)
server.on_connect do |session|
  puts "New client connected: #{session.remote_address}"
  dont_echo = Telnet::Command.new_dont(Telnet::Option::ECHO)
  io.write(dont_echo)
  puts "Sent dont echo"
end

server.on_disconnect do |session|
  puts "Client disconnected: #{session.remote_address}"
end

server.on_wont_echo do |session|
  puts "Client: WONT ECHO"
end

# Spawns listener
server.listen

while true
  Fiber.yield
end

```

## Contributing

1. Fork it (<https://github.com/mjblack/telnet/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Matthew J. Black](https://github.com/mjblack) - creator and maintainer
