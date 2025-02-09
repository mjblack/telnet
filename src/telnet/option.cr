module Telnet
  module Option
    # :nodoc:
    OPTIONS = {
      "BINARY"              => {value: 0_u8, comment: "Binary Transmission"},
      "ECHO"                => {value: 1_u8, comment: "Echo"},
      "RCP"                 => {value: 2_u8, comment: "Reconnection"},
      "SGA"                 => {value: 3_u8, comment: "Suppress Go Ahead"},
      "NAMS"                => {value: 4_u8, comment: "Approx Message Size Negotiation"},
      "STATUS"              => {value: 5_u8, comment: "Status"},
      "TM"                  => {value: 6_u8, comment: "Timing Mark"},
      "RCTE"                => {value: 7_u8, comment: "Remote Controlled Trans and Echo"},
      "NAOL"                => {value: 8_u8, comment: "Output Line Width"},
      "NAOP"                => {value: 9_u8, comment: "Output Page Size"},
      "NAOCRD"              => {value: 10_u8, comment: "Output Carriage-Return Disposition"},
      "NAOHTS"              => {value: 11_u8, comment: "Output Horizontal Tab Stops"},
      "NAOHTD"              => {value: 12_u8, comment: "Output Horizontal Tab Disposition"},
      "NAOFFD"              => {value: 13_u8, comment: "Output Formfeed Disposition"},
      "NAOVTS"              => {value: 14_u8, comment: "Output Vertical Tabstops"},
      "NAOVTD"              => {value: 15_u8, comment: "Output Vertical Tab Disposition"},
      "NAOLFD"              => {value: 16_u8, comment: "Output Linefeed Disposition"},
      "EXTASCII"            => {value: 17_u8, comment: "Extended ASCII"},
      "LOGOUT"              => {value: 18_u8, comment: "Logout"},
      "BM"                  => {value: 19_u8, comment: "Byte Macro"},
      "DET"                 => {value: 20_u8, comment: "Data Entry Terminal"},
      "SUPDUP"              => {value: 21_u8, comment: "SUPDUP"},
      "SUPDUPOUTPUT"        => {value: 22_u8, comment: "SUPDUP Output"},
      "SNDLOC"              => {value: 23_u8, comment: "Send Location"},
      "TTYPE"               => {value: 24_u8, comment: "Terminal Type"},
      "EOR"                 => {value: 25_u8, comment: "End of Record"},
      "TUID"                => {value: 26_u8, comment: "TACACS User Identification"},
      "OUTMRK"              => {value: 27_u8, comment: "Output Marking"},
      "TTYLOC"              => {value: 28_u8, comment: "Terminal Location Number"},
      "REGIME3270"          => {value: 29_u8, comment: "Telnet 3270 Regime"},
      "X3PAD"               => {value: 30_u8, comment: "X.3 PAD"},
      "NAWS"                => {value: 31_u8, comment: "Negotiate About Window Size"},
      "TSPEED"              => {value: 32_u8, comment: "Terminal Speed"},
      "LFLOW"               => {value: 33_u8, comment: "Remote Flow Control"},
      "LINEMODE"            => {value: 34_u8, comment: "Linemode"},
      "XDISPLOC"            => {value: 35_u8, comment: "X Display Location"},
      "OLDENVIRON"          => {value: 36_u8, comment: "Environment Option"},
      "AUTHENTICATION"      => {value: 37_u8, comment: "Authentication Option"},
      "ENCRYPT"             => {value: 38_u8, comment: "Encryption Option"},
      "NEWENVIRON"          => {value: 39_u8, comment: "New Environment Option"},
      "COMPORT"             => {value: 44_u8, comment: "Com Port Control Option"},
      "SUPPRESS_LOCAL_ECHO" => {value: 45_u8, comment: "Suppress Local Echo"},
      "START_TLS"           => {value: 46_u8, comment: "Start TLS"},
      "SEND_URL"            => {value: 48_u8, comment: "Send-URL"},
      "FORWARD_X"           => {value: 49_u8, comment: "Forward X"},
      "MSDP"                => {value: 69_u8, comment: "Mud Server Data"},
      "MSSP"                => {value: 70_u8, comment: "Mud Server Information"},
      "MCCP2"               => {value: 86_u8, comment: "Mud Client Compression Protocol v2"},
      "MCCP3"               => {value: 87_u8, comment: "Mud Client Compression Protocol v3"},
      "MSP"                 => {value: 90_u8, comment: "Mud Sound Protocol"},
      "MXP"                 => {value: 91_u8, comment: "Mud Extension Protocol"},
      "GMCP"                => {value: 201_u8, comment: "Generic Mud Communication Protocol"},
      "EXOPL"               => {value: 255_u8, comment: "Extended-Options-List"},
    }

    {% for key, val in OPTIONS %}
    {% unless val["comment"].empty? %}
    # {{val["comment"]}}
    {% end %}
    {{key.upcase.id}} = {{val["value"]}}
    {% end %}

    # Find the option name by value.
    # ```
    # Telnet::Option.find_option(0) # => "BINARY"
    # ```
    def self.find_option(value : UInt8) : String
      OPTIONS.find! { |k, v| v["value"] == value }.first
    end

    # Find the option value by name.
    # ```
    # Telnet::Option.find_option("BINARY") # => 0
    # ```
    def self.find_option(value : String) : UInt8
      OPTIONS[value]["value"]
    end
  end
end
