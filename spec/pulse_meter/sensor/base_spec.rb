require 'spec_helper'

describe PulseMeter::Sensor::Base do
  let(:name){ :some_sensor }
  let(:description) {"Le awesome description"}
  let!(:sensor){ described_class.new(name) }
  let(:redis){ PulseMeter.redis }

  describe '#initialize' do
    context 'when PulseMeter.redis is not initialized' do
      it "raises RedisNotInitialized exception" do
        PulseMeter.redis = nil
        expect{ described_class.new(:foo) }.to raise_exception(PulseMeter::RedisNotInitialized)
      end
    end

    context 'when PulseMeter.redis is initialized' do

      context 'when passed sensor name is bad' do
        it "raises BadSensorName exception" do
          ['name with whitespace', 'name|with|bad|characters'].each do |bad_name|
            expect{ described_class.new(bad_name) }.to raise_exception(PulseMeter::BadSensorName)
          end
        end
      end

      context 'when passed sensor name is valid' do
        it "successfully creates object" do
          expect(described_class.new("foo_@")).not_to be_nil
        end

        it "initializes attributes #redis and #name" do
          sensor = described_class.new(:foo)
          expect(sensor.name).to eq('foo')
          expect(sensor.redis).to eq(PulseMeter.redis)
        end

        it "saves dump to redis automatically to let the object be restored by name" do
          expect(described_class.restore(name)).to be_instance_of(described_class)
        end

        it "annotates object if annotation given" do
          described_class.new(:foo, :annotation => "annotation")
          sensor = described_class.restore(:foo)
          expect(sensor.annotation).to eq("annotation")
        end
      end
    end
  end

  describe '#annotate' do

    it "stores sensor annotation in redis" do
      expect {sensor.annotate(description)}.to change{redis.keys('*').count}.by(1)
    end

  end

  describe '#annotation' do
    context "when sensor was annotated" do
      it "returns stored annotation" do
        sensor.annotate(description)
        expect(sensor.annotation).to eq(description)
      end
    end

    context "when sensor was not annotated" do
      it "returns nil" do
        expect(sensor.annotation).to be_nil
      end
    end

    context "after sensor data was cleaned" do
      it "returns nil" do
        sensor.annotate(description)
        sensor.cleanup
        expect(sensor.annotation).to be_nil
      end
    end
  end

  describe "#cleanup" do
    it "removes from redis all sensor data" do
      sensor.event(123)
      sensor.annotate(description)
      sensor.cleanup
      expect(redis.keys('*')).to be_empty
    end
  end

  describe "#event" do
    context "when everything is ok" do
      it "does nothing and return true" do
        expect(sensor.event(nil)).to be
      end
    end

    context "when an error occures while processing event" do
      it "catches StandardErrors and return false" do
        allow(sensor).to receive(:process_event) {raise StandardError}
        expect(sensor.event(nil)).not_to be
      end
    end
  end

end
