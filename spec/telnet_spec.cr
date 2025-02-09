require "./spec_helper"

describe Telnet do
  describe "Telnet Constants" do
    it "should have a NULL const" do
      Telnet::NULL.should eq(0_u8)
    end

    it "should have a CR const" do
      Telnet::CR.should eq(13_u8)
    end

    it "should have a LF const" do
      Telnet::LF.should eq(10_u8)
    end

    it "should have a MAX_BUFFER_SIZE const" do
      Telnet::MAX_BUFFER_SIZE.should eq(4096)
    end
  end
end
