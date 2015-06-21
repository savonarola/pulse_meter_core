require 'spec_helper'

describe PulseMeter::Sensor::HashedIndicator do
  let(:name){ :some_counter }
  let(:sensor){ described_class.new(name) }
  let(:redis){ PulseMeter.redis }

  describe "#event" do
    it "sets sensor value to passed value" do
      expect{ sensor.event("foo" => 10.4) }.to change{ sensor.value["foo"] }.from(0).to(10.4)
      expect{ sensor.event("foo" => 15.1) }.to change{ sensor.value["foo"] }.from(10.4).to(15.1)
    end

    it "takes multiple events" do
      data = {"foo" => 1.1, "boo" => 2.2}
      sensor.event(data)
      expect(sensor.value).to eq(data)
    end
  end

  describe "#value_key" do
    it "is composed of sensor name and pulse_meter:value: prefix" do
      expect(sensor.value_key).to eq("pulse_meter:value:#{name}")
    end
  end

  describe "#value" do
    it "has initial value 0" do
      expect(sensor.value["foo"]).to eq(0)
    end

    it "stores redis hash by value_key" do
      sensor.event({"foo" => 1})
      expect(sensor.value).to eq({"foo" => 1})
      expect(redis.hgetall(sensor.value_key)).to eq({"foo" => "1.0"})
    end
  end

end
