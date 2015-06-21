require 'spec_helper'

describe PulseMeter::CommandAggregator::Async do
  let(:ca){PulseMeter.command_aggregator}
  let(:redis){PulseMeter.redis}

  describe "#multi" do
    it "accumulates redis command and execute in a bulk" do
      ca.multi do
        ca.set("xxxx", "zzzz")
        ca.set("yyyy", "zzzz")
        sleep 0.1
        expect(redis.get("xxxx")).to be_nil
        expect(redis.get("yyyy")).to be_nil
      end
      ca.wait_for_pending_events
      expect(redis.get("xxxx")).to eq("zzzz")
      expect(redis.get("yyyy")).to eq("zzzz")
    end
  end

  describe "any other redis instance method" do
    it "is delegated to redis" do
      ca.set("xxxx", "zzzz")
      ca.wait_for_pending_events
      expect(redis.get("xxxx")).to eq("zzzz")
    end

    it "is aggregated if queue is not overflooded" do
      redis.set("x", 0)
      ca.max_queue_length.times{ ca.incr("x") }
      ca.wait_for_pending_events
      expect(redis.get("x").to_i).to eq(ca.max_queue_length)
    end

    it "is not aggregated if queue is overflooded" do
      redis.set("x", 0)
      (ca.max_queue_length * 2).times{ ca.incr("x") }
      ca.wait_for_pending_events
      expect(redis.get("x").to_i).to be < 2 * ca.max_queue_length
    end
  end

  describe "#wait_for_pending_events" do
    it "pauses execution until aggregator thread sends all commands ro redis" do
      ca.set("xxxx", "zzzz")
      expect(redis.get("xxxx")).to be_nil
      ca.wait_for_pending_events
      expect(redis.get("xxxx")).to eq("zzzz")
    end
  end

end
