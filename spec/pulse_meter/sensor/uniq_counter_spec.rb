require 'spec_helper'

describe PulseMeter::Sensor::UniqCounter do
  let(:name){ :some_counter }
  let(:sensor){ described_class.new(name) }
  let(:redis){ PulseMeter.redis }

  describe "#event" do
    it "counts unique values" do
      expect{ sensor.event(:first) }.to change{sensor.value}.to(1)
      expect{ sensor.event(:first) }.not_to change{sensor.value}
      expect{ sensor.event(:second) }.to change{sensor.value}.from(1).to(2)
    end
  end

  describe "#value" do
    it "has initial value 0" do
      expect(sensor.value).to eq(0)
    end

    it "returns count of unique values" do
      data = (1..100).map {rand(200)}
      data.each {|e| sensor.event(e)}
      expect(sensor.value).to eq(data.uniq.count)
    end
  end

end
