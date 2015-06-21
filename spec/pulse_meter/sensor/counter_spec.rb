require 'spec_helper'

describe PulseMeter::Sensor::Counter do
  let(:name){ :some_counter }
  let(:sensor){ described_class.new(name) }
  let(:redis){ PulseMeter.redis }

  describe "#event" do
    it "increments sensor value by passed value" do
      expect{ sensor.event(10) }.to change{ sensor.value }.from(0).to(10)
      expect{ sensor.event(15) }.to change{ sensor.value }.from(10).to(25)
    end

    it "truncates increment value" do
      expect{ sensor.event(10.4) }.to change{ sensor.value }.from(0).to(10)
      expect{ sensor.event(15.1) }.to change{ sensor.value }.from(10).to(25)
    end
  end

  describe "#value_key" do
    it "is composed of sensor name and pulse_meter:value: prefix" do
      expect(sensor.value_key).to eq("pulse_meter:value:#{name}")
    end
  end

  describe "#value" do
    it "has initial value 0" do
      expect(sensor.value).to eq(0)
    end

    it "stores stringified value by value_key" do
      sensor.event(123)
      expect(sensor.value).to eq(123)
      expect(redis.get(sensor.value_key)).to eq('123')
    end
  end

  describe "#incr" do
    it "increments value by 1" do
      expect{ sensor.incr }.to change{ sensor.value }.from(0).to(1)
      expect{ sensor.incr }.to change{ sensor.value }.from(1).to(2)
    end
  end

  describe "#cleanup" do
    it "removes all sensor data" do
      sensor.annotate("My Counter")
      sensor.event(123)
      sensor.cleanup
      expect(redis.keys('*')).to be_empty
    end
  end

end
