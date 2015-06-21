require 'spec_helper'

describe PulseMeter::Observer do

  context "instance methods observation" do
    let!(:dummy) {ObservedDummy.new}
    let!(:sensor) {PulseMeter::Sensor::Counter.new(:foo)}
    before do
      [:incr, :error].each {|m| described_class.unobserve_method(ObservedDummy, m)}
    end

    def create_observer(method = :incr, increment = 1)
      described_class.observe_method(ObservedDummy, method, sensor) do |*args|
        event(increment)
      end
    end

    def remove_observer(method = :incr)
      described_class.unobserve_method(ObservedDummy, method)
    end

    describe ".observe_method" do
      it "executes block in context of sensor each time specified method of given class called" do
        create_observer
        5.times {dummy.incr}
        expect(sensor.value).to eq(5)
      end
      
      it "passes arguments to observed method" do
        create_observer
        5.times {dummy.incr(10)}
        expect(dummy.count).to eq(50)
      end

      it "passes methods' params to block" do
        described_class.observe_method(ObservedDummy, :incr, sensor) do |time, cnt|
          event(cnt)
        end

        5.times {dummy.incr(10)}
        expect(sensor.value).to eq(50)
      end

      it "passes execution time in milliseconds to block" do
        Timecop.freeze do
          described_class.observe_method(ObservedDummy, :incr, sensor) do |time, cnt|
            event(time)
          end

          dummy.incr
          expect(sensor.value).to be >= 1000
        end
      end

      it "does not break observed method even is observer raises error" do
        described_class.observe_method(ObservedDummy, :incr, sensor) do |*args|
          raise RuntimeError
        end

        expect {dummy.incr}.not_to raise_error
        expect(dummy.count).to eq(1)
      end

      it "uses first observer in case of double observation" do
        create_observer(:incr, 1)
        create_observer(:incr, 2)
        5.times {dummy.incr}
        expect(sensor.value).to eq(5)
      end

      it "keeps observed methods' errors" do
        create_observer(:error)
        expect {dummy.error}.to raise_error
        expect(sensor.value).to eq(1)
      end

      it "makes observed method return its value" do
        create_observer
        expect(dummy.incr).to eq(1)
      end

      it "allows to pass blocks to observed method" do
        create_observer
        dummy.incr do
          2
        end
        expect(dummy.count).to eq(3)
      end
    end

    describe ".unobserve_method" do
      it "does nothing unless method is observed" do
        expect {remove_observer}.not_to raise_error
      end

      it "removes observation from observed method" do
        create_observer
        dummy.incr
        remove_observer
        dummy.incr
        expect(sensor.value).to eq(1)
      end
    end
  end

  context "class methods observation" do
    let!(:dummy) {ObservedDummy}
    let!(:sensor) {PulseMeter::Sensor::Counter.new(:foo)}
    before do
      dummy.reset
      [:incr, :error].each {|m| described_class.unobserve_class_method(ObservedDummy, m)}
    end

    def create_observer(method = :incr, increment = 1)
      described_class.observe_class_method(ObservedDummy, method, sensor) do |*args|
        event(increment)
      end
    end

    def remove_observer(method = :incr)
      described_class.unobserve_class_method(ObservedDummy, method)
    end

    describe ".observe_class_method" do
      it "executes block in context of sensor each time specified method of given class called" do
        create_observer
        5.times {dummy.incr}
        expect(sensor.value).to eq(5)
      end
      
      it "passes arguments to observed method" do
        create_observer
        5.times {dummy.incr(10)}
        expect(dummy.count).to eq(50)
      end

      it "passes methods' params to block" do
        described_class.observe_class_method(ObservedDummy, :incr, sensor) do |time, cnt|
          event(cnt)
        end

        5.times {dummy.incr(10)}
        expect(sensor.value).to eq(50)
      end

      it "passes execution time in milliseconds to block" do
        Timecop.freeze do
          described_class.observe_class_method(ObservedDummy, :incr, sensor) do |time, cnt|
            event(time)
          end

          dummy.incr
          expect(sensor.value).to eq(1000)
        end
      end

      it "does not break observed method even is observer raises error" do
        described_class.observe_class_method(ObservedDummy, :incr, sensor) do |*args|
          raise RuntimeError
        end

        expect {dummy.incr}.not_to raise_error
        expect(dummy.count).to eq(1)
      end

      it "uses first observer in case of double observation" do
        create_observer(:incr, 1)
        create_observer(:incr, 2)
        5.times {dummy.incr}
        expect(sensor.value).to eq(5)
      end

      it "keeps observed methods' errors" do
        create_observer(:error)
        expect {dummy.error}.to raise_error
        expect(sensor.value).to eq(1)
      end

      it "makes observed method return its value" do
        create_observer
        expect(dummy.incr).to eq(1)
      end

      it "allows to pass blocks to observed method" do
        create_observer
        dummy.incr do
          2
        end
        expect(dummy.count).to eq(3)
      end
    end

    describe ".unobserve_class_method" do
      it "does nothing unless method is observed" do
        expect {remove_observer}.not_to raise_error
      end

      it "removes observation from observed method" do
        create_observer
        dummy.incr
        remove_observer
        dummy.incr
        expect(sensor.value).to eq(1)
      end
    end
  end
end
