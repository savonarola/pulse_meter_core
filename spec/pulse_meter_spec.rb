require 'spec_helper'

describe PulseMeter do
  describe "::redis=" do
    it "stores redis" do
      PulseMeter.redis = 'redis'
      expect(PulseMeter.redis).to eq('redis')
    end
  end
  describe "::redis" do
    it "retrieves redis" do
      PulseMeter.redis = 'redis'
      expect(PulseMeter.redis).to eq('redis')
    end
  end
  describe "::command_aggregator=" do
    context "when :async passed" do
      it "sets async command_aggregator to be used" do
        PulseMeter.command_aggregator = :async
        expect(PulseMeter.command_aggregator).to be_kind_of(PulseMeter::CommandAggregator::Async)
      end
    end
    context "when :sync passed" do
      it "sets sync command_aggregator to be used" do
        PulseMeter.command_aggregator = :sync
        expect(PulseMeter.command_aggregator).to be_kind_of(PulseMeter::CommandAggregator::Sync)
      end
    end
    context "otherwise" do
      it "sets command_aggregator to the passed value" do
        PulseMeter.command_aggregator = :xxx
        expect(PulseMeter.command_aggregator).to eq(:xxx)
      end
    end
  end

  describe "::command_aggregator" do
    it "returns current command_aggregator" do
      PulseMeter.command_aggregator = :async
      expect(PulseMeter.command_aggregator).to be_kind_of(PulseMeter::CommandAggregator::Async)
      PulseMeter.command_aggregator = :sync
      expect(PulseMeter.command_aggregator).to be_kind_of(PulseMeter::CommandAggregator::Sync)
    end

    it "always returns the same command_aggregator for each type" do
      PulseMeter.command_aggregator = :async
      ca1 = PulseMeter.command_aggregator
      PulseMeter.command_aggregator = :sync
      PulseMeter.command_aggregator = :async
      ca2 = PulseMeter.command_aggregator
      expect(ca1).to eq(ca2)
    end
  end

  describe "::logger" do
    it "returns PulseMeter logger" do
      PulseMeter.logger = 123
      expect(PulseMeter.logger).to eq(123)
    end

    it "returns default logger" do
      PulseMeter.logger = nil
      expect(PulseMeter.logger).to be_kind_of(Logger)
    end
  end

  describe "::error" do
    it "delegates error message to logger" do
      expect(PulseMeter.logger).to receive(:error)
      PulseMeter.error("foo")
    end
  end
end
