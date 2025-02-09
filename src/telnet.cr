require "socket"

require "./telnet/command"
require "./telnet/option"
require "./telnet/parser"
require "./telnet/descriptor"
require "./telnet/session"
require "./telnet/client"
require "./telnet/server"

module Telnet
  VERSION = {{`shards version #{__DIR__}`.chomp.stringify}}

  MAX_BUFFER_SIZE = 4096

  CR = 13_u8
  LF = 10_u8
  NULL = 0_u8
end
