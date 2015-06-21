require 'spec_helper'

describe PulseMeter::Observer::Extended do
  context "instance methods observation" do
    let!(:dummy) {ObservedDummy.new}
    let!(:sensor) {PulseMeter::Sensor::Counter.new(:foo)}
    before do
      [:incr, :error].each {|m| described_class.unobserve_method(ObservedDummy, m)}
    end

    describe ".observe_method" do
      it "passes exended parameters to block in normal execution" do
        Timecop.freeze do
          parameters = {}

          described_class.observe_method(ObservedDummy, :incr, sensor) do |params|
            parameters = params
          end

          dummy.incr(40)

          expect(parameters[:self]).to eq(dummy)
          expect(parameters[:delta]).to be >= 1000
          expect(parameters[:result]).to eq(40)
          expect(parameters[:exception]).to be_nil
          expect(parameters[:args]).to eq([40])
        end
      end

      it "passes exended parameters to block with exception" do
        Timecop.freeze do
          parameters = {}

          described_class.observe_method(ObservedDummy, :error, sensor) do |params|
            parameters = params
          end

          expect { dummy.error }.to raise_error(RuntimeError)

          expect(parameters[:self]).to eq(dummy)
          expect(parameters[:result]).to eq(nil)
          expect(parameters[:exception].class).to eq(RuntimeError)
          expect(parameters[:args]).to eq([])
        end
      end
    end
  end

  context "class methods observation" do
    let!(:sensor) {PulseMeter::Sensor::Counter.new(:foo)}
    before do
      [:incr, :error].each {|m| described_class.unobserve_class_method(ObservedDummy, m)}
    end

    describe ".observe_class_method" do
      it "passes exended parameters to block in normal execution" do
        Timecop.freeze do
          parameters = {}

          described_class.observe_class_method(ObservedDummy, :incr, sensor) do |params|
            parameters = params
          end
  
          ObservedDummy.incr(40)

          expect(parameters[:self]).to eq(ObservedDummy)
          expect(parameters[:delta]).to be >= 1000
          expect(parameters[:result]).to eq(40)
          expect(parameters[:exception]).to be_nil
          expect(parameters[:args]).to eq([40])
        end
      end

      it "passes exended parameters to block with exception" do
        Timecop.freeze do
          parameters = {}

          described_class.observe_class_method(ObservedDummy, :error, sensor) do |params|
            parameters = params
          end
  
          expect { ObservedDummy.error }.to raise_error(RuntimeError)

          expect(parameters[:self]).to eq(ObservedDummy)
          expect(parameters[:result]).to eq(nil)
          expect(parameters[:exception].class).to eq(RuntimeError)
          expect(parameters[:args]).to eq([])
        end
      end
    end
  end
end