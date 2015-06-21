require 'spec_helper'

describe PulseMeter::CommandAggregator::Sync do
  let(:ca){described_class.instance}
  let(:redis){PulseMeter.redis}

  describe "#multi" do
    it "accumulates redis command and execute in a bulk" do
      ca.multi do
        ca.set("xxxx", "zzzz")
        ca.set("yyyy", "zzzz")
      end
      expect(redis.get("xxxx")).to eq("zzzz")
      expect(redis.get("yyyy")).to eq("zzzz")
    end
  end

  describe "any other redis instance method" do
    it "is delegated to redis" do
      ca.set("xxxx", "zzzz")
      expect(redis.get("xxxx")).to eq("zzzz")
    end
  end
end

