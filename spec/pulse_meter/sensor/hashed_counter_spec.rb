require 'spec_helper'

describe PulseMeter::Sensor::HashedCounter do
  let(:name){ :some_counter }
  let(:sensor){ described_class.new(name) }
  let(:redis){ PulseMeter.redis }

  describe "#event" do
    it "increments sensor value by passed value" do
      expect{ sensor.event({"foo" => 10}) }.to change{ sensor.value["foo"] }.from(0).to(10)
      expect{ sensor.event({"foo" => 15}) }.to change{ sensor.value["foo"] }.from(10).to(25)
    end

    it "truncates increment value" do
      expect{ sensor.event({"foo" => 10.4}) }.to change{ sensor.value["foo"] }.from(0).to(10)
      expect{ sensor.event({"foo" => 15.1}) }.to change{ sensor.value["foo"] }.from(10).to(25)
    end

    it "increments total value" do
      expect{ sensor.event({"foo" => 1, "bar" => 2}) }.to change{sensor.value["total"]}.from(0).to(3)
    end
  end

  describe "#value" do
    it "has initial value 0" do
      expect(sensor.value["foo"]).to eq(0)
    end

    it "stores redis hash by value_key" do
      sensor.event({"foo" => 1})
      expect(sensor.value).to eq({"foo" => 1, "total" => 1})
      expect(redis.hgetall(sensor.value_key)).to eq({"foo" => "1", "total" => "1"})
    end
  end

  describe "#incr" do
    it "increments key value by 1" do
      expect{ sensor.incr("foo") }.to change{ sensor.value["foo"] }.from(0).to(1)
      expect{ sensor.incr("foo") }.to change{ sensor.value["foo"] }.from(1).to(2)
    end
  end

end
