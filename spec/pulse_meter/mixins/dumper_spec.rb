require 'spec_helper'

describe PulseMeter::Mixins::Dumper do
  class Base
    include PulseMeter::Mixins::Dumper
  end

  class Bad < Base; end

  class Undumpable < Base
    def name; :name; end

    def redis; PulseMeter.redis; end

    def initialize
      @socket = Socket.new(:INET, :STREAM)
    end
  end

  class Good < Base
    attr_accessor :foo
    def name; :name; end

    def redis; PulseMeter.redis; end

    def initialize(foo)
      @foo = foo
    end
  end

  let(:bad_obj){ Bad.new }
  let(:undumpable_obj){ Undumpable.new }
  let(:good_obj){ Good.new(:foo) }
  let(:redis){ PulseMeter.redis }

  describe '#dump' do
    context "when class violates dump contract" do
      context "when it has no name attribute" do
        it "should raise exception" do
          def bad_obj.redis; PulseMeter.redis; end
          expect{ bad_obj.dump! }.to raise_exception(PulseMeter::DumpError)
        end
      end

      context "when it has no redis attribute" do
        it "should raise exception" do
          def bad_obj.name; :foo; end
          expect{ bad_obj.dump! }.to raise_exception(PulseMeter::DumpError)
        end
      end

      context "when redis is not avalable" do
        it "should raise exception" do
          def bad_obj.name; :foo; end
          def bad_obj.redis; nil; end
          expect{ bad_obj.dump! }.to raise_exception(PulseMeter::DumpError)
        end
      end

      context "when object cannot be dumped" do
        it "should raise exception" do
          expect {undumpable_obj.dump!}.to raise_exception(PulseMeter::DumpError)
        end
      end
    end

    context "when class follows dump contract" do
      it "should not raise dump exception" do
        expect {good_obj.dump!}.not_to raise_exception(PulseMeter::DumpError)
      end

      it "should save dump to redis" do
        expect {good_obj.dump!}.to change {redis.hlen(Good::DUMP_REDIS_KEY)}.by(1)
      end
    end
  end

  describe ".restore" do
    context "when object has never been dumped" do
      it "should raise exception" do
        expect{ Base.restore(:nonexistant) }.to raise_exception(PulseMeter::RestoreError)
      end
    end

    context "when object was dumped" do
      before do
        good_obj.dump!
      end

      it "should keep object class" do
        Base.restore(good_obj.name).should be_instance_of(good_obj.class)
      end

      it "should restore object data" do
        restored = Base.restore(good_obj.name)
        restored.foo.should == good_obj.foo
      end

      it "should restore last dumped object" do
        good_obj.foo = :bar
        good_obj.dump!
        restored = Base.restore(good_obj.name)
        restored.foo.should == :bar
      end
    end
  end

  describe "#cleanup_dump" do
    it "should remove data from redis" do
      good_obj.dump!
      good_obj.cleanup_dump
      redis.keys('*').count.should == 0
    end
  end
end
