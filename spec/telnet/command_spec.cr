require "spec"
require "../spec_helper"

describe Telnet::Command do
  describe "Telnet Constants" do
    it "should have an IS command" do
      Telnet::Command::IS.should eq(0_u8)
    end

    it "should have a SEND command" do
      Telnet::Command::SEND.should eq(1_u8)
    end

    it "should have a IAC command" do
      Telnet::Command::IAC.should eq(255_u8)
    end

    it "should have a DONT command" do
      Telnet::Command::DONT.should eq(254_u8)
    end

    it "should have a DO command" do
      Telnet::Command::DO.should eq(253_u8)
    end

    it "should have a WONT command" do
      Telnet::Command::WONT.should eq(252_u8)
    end

    it "should have a WILL command" do
      Telnet::Command::WILL.should eq(251_u8)
    end

    it "should have a SB command" do
      Telnet::Command::SB.should eq(250_u8)
    end

    it "should have a GA command" do
      Telnet::Command::GA.should eq(249_u8)
    end

    it "should have a EL command" do
      Telnet::Command::EL.should eq(248_u8)
    end

    it "should have a EC command" do
      Telnet::Command::EC.should eq(247_u8)
    end

    it "should have a AYT command" do
      Telnet::Command::AYT.should eq(246_u8)
    end

    it "should have a AO command" do
      Telnet::Command::AO.should eq(245_u8)
    end

    it "should have a IP command" do
      Telnet::Command::IP.should eq(244_u8)
    end

    it "should have a BREAK command" do
      Telnet::Command::BREAK.should eq(243_u8)
    end

    it "should have a DM command" do
      Telnet::Command::DM.should eq(242_u8)
    end
  end

  describe "Telnet Command Methods" do
    it "should create a new DO command" do
      Telnet::Command.new_do(1_u8).should eq("\xff\xfd\x01".to_slice)
    end

    it "should create a new DONT command" do
      Telnet::Command.new_dont(1_u8).should eq("\xff\xfe\x01".to_slice)
    end

    it "should create a new WILL command" do
      Telnet::Command.new_will(1_u8).should eq("\xff\xfb\x01".to_slice)
    end

    it "should create a new WONT command" do
      Telnet::Command.new_wont(1_u8).should eq("\xff\xfc\x01".to_slice)
    end

    it "should create a new subnegotiation command" do
      # IAC (255), SB (250), option (1), data ([2, 3]), IAC (255), SE (240)
      Telnet::Command.new_subneg(1_u8, [2_u8, 3_u8]).should eq("\xff\xfa\x01\x02\x03\xff\xf0".to_slice)
    end

    it "should create a new subnegotiation IS command" do
      # IAC (255), SB (250), option (1), IS (0), data ([2, 3]), IAC (255), SE (240)
      Telnet::Command.new_subneg_is(1_u8, [2_u8, 3_u8]).should eq("\xff\xfa\x01\x00\x02\x03\xff\xf0".to_slice)
    end

    it "should create a new subnegotiation SEND command" do
      # IAC   (255), SB (250), option (1), SEND (1), data ([2, 3]), IAC (255), SE (240)
      Telnet::Command.new_subneg_send(1_u8, [2_u8, 3_u8]).should eq("\xff\xfa\x01\x01\x02\x03\xff\xf0".to_slice)
    end

    it "should find commands by name" do
      Telnet::Command.find_command(255_u8).should eq("IAC")
      Telnet::Command.find_command(254_u8).should eq("DONT")
      Telnet::Command.find_command(253_u8).should eq("DO")
      Telnet::Command.find_command(252_u8).should eq("WONT")
      Telnet::Command.find_command(251_u8).should eq("WILL")
      Telnet::Command.find_command(250_u8).should eq("SB")
      Telnet::Command.find_command(249_u8).should eq("GA")
      Telnet::Command.find_command(248_u8).should eq("EL")
      Telnet::Command.find_command(247_u8).should eq("EC")
      Telnet::Command.find_command(246_u8).should eq("AYT")
      Telnet::Command.find_command(245_u8).should eq("AO")
      Telnet::Command.find_command(244_u8).should eq("IP")
      Telnet::Command.find_command(243_u8).should eq("BREAK")
      Telnet::Command.find_command(242_u8).should eq("DM")
      Telnet::Command.find_command(241_u8).should eq("NOP")
      Telnet::Command.find_command(240_u8).should eq("SE")
      Telnet::Command.find_command(239_u8).should eq("EOR")
      Telnet::Command.find_command(238_u8).should eq("ABORT")
      Telnet::Command.find_command(237_u8).should eq("SUSP")
      Telnet::Command.find_command(236_u8).should eq("EOF")
    end

    it "should find commands by name" do
      Telnet::Command.find_command("IAC").should eq(255_u8)
      Telnet::Command.find_command("DONT").should eq(254_u8)
      Telnet::Command.find_command("DO").should eq(253_u8)
      Telnet::Command.find_command("WONT").should eq(252_u8)
      Telnet::Command.find_command("WILL").should eq(251_u8)
      Telnet::Command.find_command("SB").should eq(250_u8)
      Telnet::Command.find_command("GA").should eq(249_u8)
      Telnet::Command.find_command("EL").should eq(248_u8)
      Telnet::Command.find_command("EC").should eq(247_u8)
      Telnet::Command.find_command("AYT").should eq(246_u8)
      Telnet::Command.find_command("AO").should eq(245_u8)
      Telnet::Command.find_command("IP").should eq(244_u8)
      Telnet::Command.find_command("BREAK").should eq(243_u8)
      Telnet::Command.find_command("DM").should eq(242_u8)
      Telnet::Command.find_command("NOP").should eq(241_u8)
      Telnet::Command.find_command("SE").should eq(240_u8)
      Telnet::Command.find_command("EOR").should eq(239_u8)
      Telnet::Command.find_command("ABORT").should eq(238_u8)
      Telnet::Command.find_command("SUSP").should eq(237_u8)
      Telnet::Command.find_command("EOF").should eq(236_u8)
    end
  end
end
