#! /usr/bin/env rspec

require_relative "test_helper"

require "yast"

Yast.import "LanItems"

module Yast
  describe LanItems do
    let(:netconfig_items) do
      {
        "eth"  => {
          "eth1" => { "BOOTPROTO" => "none" },
          "eth2" => { "BOOTPROTO" => "none" },
          "eth4" => { "BOOTPROTO" => "none" },
          "eth5" => { "BOOTPROTO" => "none" },
          "eth6" => { "BOOTPROTO" => "dhcp" }
        },
        "bond" => {
          "bond0" => {
            "BOOTPROTO"      => "static",
            "BONDING_MASTER" => "yes",
            "BONDING_SLAVE0" => "eth1",
            "BONDING_SLAVE1" => "eth2"
          },
          "bond1" => {
            "BOOTPROTO"      => "static",
            "BONDING_MASTER" => "yes"
          }
        }
      }
    end
    let(:hwinfo_items) do
      [
        { "dev_name" => "eth11" },
        { "dev_name" => "eth12" }
      ]
    end

    before(:each) do
      allow(NetworkInterfaces).to receive(:FilterDevices).with("netcard") { netconfig_items }

      allow(LanItems).to receive(:ReadHardware) { hwinfo_items }
      LanItems.Read
    end

    describe "#GetBondableInterfaces" do
      let(:expected_bondable) { ["eth4", "eth5", "eth11", "eth12"] }

      context "on common architectures" do
        before(:each) do
          expect(Arch).to receive(:s390).at_least(:once).and_return false
          # FindAndSelect initializes internal state of LanItems it
          # is used internally by some helpers
          LanItems.FindAndSelect("bond1")
        end

        it "returns list of slave candidates" do
          expect(
            LanItems
              .GetBondableInterfaces(LanItems.GetCurrentName)
              .map { |i| LanItems.GetDeviceName(i) }
          ).to match_array expected_bondable
        end
      end

      context "on s390" do
        before(:each) do
          expect(Arch).to receive(:s390).at_least(:once).and_return true
        end

        it "returns list of slave candidates" do
          expect(LanItems).to receive(:s390_ReadQethConfig).with("eth4")
            .and_return("QETH_LAYER2" => "yes")
          expect(LanItems).to receive(:s390_ReadQethConfig).with(::String)
            .at_least(:once).and_return("QETH_LAYER2" => "no")

          expect(
            LanItems
              .GetBondableInterfaces(LanItems.GetCurrentName)
              .map { |i| LanItems.GetDeviceName(i) }
          ).to match_array ["eth4"]
        end
      end
    end

    describe "#GetBondSlaves" do
      it "returns list of slaves if bond device has some" do
        expect(LanItems.GetBondSlaves("bond0")).to match_array ["eth1", "eth2"]
      end

      it "returns empty list if bond device doesn't have slaves assigned" do
        expect(LanItems.GetBondSlaves("bond1")).to be_empty
      end
    end

    describe "#BuildBondIndex" do
      let(:expected_mapping) { { "eth1" => "bond0", "eth2" => "bond0" } }

      it "creates mapping of device names to corresponding bond master" do
        expect(LanItems.BuildBondIndex).to match(expected_mapping)
      end
    end
  end
end
