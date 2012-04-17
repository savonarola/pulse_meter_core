require 'spec_helper'

describe PulseMeter::Sensor::Base do
  let(:name){ :some_sensor }
  let(:description) {"Le awesome description"}
  let(:sensor){ described_class.new(name) }
  let(:redis){ PulseMeter.redis }

  describe '#initialize' do
    context 'when PulseMeter.redis is not initialized' do
      it "should raise RedisNotInitialized exception" do
        PulseMeter.redis = nil
        expect{ described_class.new(:foo) }.to raise_exception(PulseMeter::RedisNotInitialized)
      end
    end

    context 'when PulseMeter.redis is initialized' do

      context 'when passed sensor name is bad' do
        it "should raise BadSensorName exception" do
          ['name with whitespace', 'name|with|bad|characters'].each do |bad_name|
            expect{ described_class.new(bad_name) }.to raise_exception(PulseMeter::BadSensorName)
          end
        end
      end

      context 'when passed sensor name is valid' do
        it "should successfully create object" do
          described_class.new(:foo).should_not be_nil
        end

        it "should initialize attributes #redis and #name" do
          sensor = described_class.new(:foo)
          sensor.name.should == 'foo'
          sensor.redis.should == PulseMeter.redis
        end
      end
    end
  end

  describe '#annotate' do

    it "should store sensor annotation in redis" do
      sensor.annotate(description)
      redis.keys('*').count.should == 1
    end

  end

  describe '#annotation' do
    context "when sensor was annotated" do
      it "should return stored annotation" do
        sensor.annotate(description)
        sensor.annotation.should == description
      end
    end

    context "when sensor was not annotated" do
      it "should return nil" do
        sensor.annotation.should be_nil
      end
    end

    context "after sensor data was cleaned" do
      it "should return nil" do
        sensor.annotate(description)
        sensor.cleanup
        sensor.annotation.should be_nil
      end
    end
  end

  describe "#cleanup" do
    it "should remove from redis all sensor data" do
      sensor.event(123)
      sensor.annotate(description)
      sensor.cleanup
      redis.keys('*').should be_empty
    end
  end

  describe "#event" do
    it "should actually do nothing for base sensor" do
      sensor.event(nil)
    end
  end

end
