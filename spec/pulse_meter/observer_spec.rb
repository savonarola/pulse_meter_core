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

      context "works independently on inherited classes with" do
        let!(:parent_sensor) {PulseMeter::Sensor::Counter.new(:parent)}
        let!(:child_sensor) {PulseMeter::Sensor::Counter.new(:child)}

        before do
          [:instance_method, :instance_method_i, :only_parent_method, :only_parent_method_i].each do |method|
            described_class.observe_method(ParentDummy, method, parent_sensor) {|*args| incr}
            described_class.observe_method(ChildDummy, method, child_sensor) {|*args| incr}
          end
        end

        after do
          expect(parent_sensor.value).to eq(1)
          expect(child_sensor.value).to eq(1)
        end

        it "redefined methods" do
          expect(ParentDummy.new.instance_method).to eq('parent#instance')
          expect(ChildDummy.new.instance_method).to eq('child#instance')
        end

        it "redefined methods, inverse order" do
          expect(ChildDummy.new.instance_method_i).to eq('child#instance_i')
          expect(ParentDummy.new.instance_method_i).to eq('parent#instance_i')
        end

        it "inherited methods" do
          expect(ParentDummy.new.only_parent_method).to eq('parent#only_parent')
          expect(ChildDummy.new.only_parent_method).to eq('parent#only_parent')
        end

        it "inherited methods, inverse order" do
          expect(ChildDummy.new.only_parent_method_i).to eq('parent#only_parent_i')
          expect(ParentDummy.new.only_parent_method_i).to eq('parent#only_parent_i')
        end
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

      context "works independently on inherited classes with" do
        before do
          [:instance_method, :only_parent_method].each do |method|
            described_class.observe_method(ParentDummy, method, sensor)
            described_class.observe_method(ChildDummy, method, sensor)

            described_class.unobserve_method(ParentDummy, method)
            described_class.unobserve_method(ChildDummy, method)
          end
        end

        it "redefined methods" do
          expect(ParentDummy.new.instance_method).to eq('parent#instance')
          expect(ChildDummy.new.instance_method).to eq('child#instance')
        end

        it "inherited methods" do
          expect(ParentDummy.new.only_parent_method).to eq('parent#only_parent')
          expect(ChildDummy.new.only_parent_method).to eq('parent#only_parent')
        end
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

      context "works independently on inherited classes with" do
        let!(:parent_sensor) {PulseMeter::Sensor::Counter.new(:parent)}
        let!(:child_sensor) {PulseMeter::Sensor::Counter.new(:child)}

        before do
          [:class_method, :class_method_i, :only_parent_class_method, :only_parent_class_method_i].each do |method|
            described_class.observe_class_method(ParentDummy, method, parent_sensor) {|*args| incr}
            described_class.observe_class_method(ChildDummy, method, child_sensor) {|*args| incr}
          end
        end

        after do
          expect(parent_sensor.value).to eq(1)
          expect(child_sensor.value).to eq(1)
        end

        it "redefined methods" do
          expect(ParentDummy.class_method).to eq('parent.class')
          expect(ChildDummy.class_method).to eq('child.class')
        end

        it "redefined methods, inverse order" do
          expect(ChildDummy.class_method_i).to eq('child.class_i')
          expect(ParentDummy.class_method_i).to eq('parent.class_i')
        end

        it "inherited methods" do
          expect(ParentDummy.only_parent_class_method).to eq('parent.class')
          expect(ChildDummy.only_parent_class_method).to eq('parent.class')
        end

        it "inherited methods, inverse order" do
          expect(ChildDummy.only_parent_class_method_i).to eq('parent.class_i')
          expect(ParentDummy.only_parent_class_method_i).to eq('parent.class_i')
        end
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

      context "works independently on inherited classes with" do
        before do
          [:class_method, :only_parent_class_method].each do |method|
            described_class.observe_class_method(ParentDummy, method, sensor)
            described_class.observe_class_method(ChildDummy, method, sensor)

            described_class.unobserve_class_method(ParentDummy, method)
            described_class.unobserve_class_method(ChildDummy, method)
          end
        end

        it "redefined methods" do
          expect(ParentDummy.class_method).to eq('parent.class')
          expect(ChildDummy.class_method).to eq('child.class')
        end

        it "inherited methods" do
          expect(ParentDummy.only_parent_class_method).to eq('parent.class')
          expect(ChildDummy.only_parent_class_method).to eq('parent.class')
        end
      end
    end
  end
end
