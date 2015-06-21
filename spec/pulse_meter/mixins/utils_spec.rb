require 'spec_helper'

describe PulseMeter::Mixins::Utils do
  class Dummy
    include PulseMeter::Mixins::Utils
  end

  let(:dummy){ Dummy.new }

  describe '#constantize' do
    context "when argument is a string with a valid class name" do
      it "returns class" do
        expect(dummy.constantize("PulseMeter::Mixins::Utils")).to eq(PulseMeter::Mixins::Utils)
      end
    end
    context "when argument is a string with invalid class name" do
      it "returns nil" do
        expect(dummy.constantize("Pumpkin::Eater")).to be_nil
      end
    end
    context "when argument is not a string" do
      it "returns nil" do
        expect(dummy.constantize({})).to be_nil
      end
    end
  end

  describe "#assert_positive_integer!" do
    it "extracts integer value from hash by passed key" do
      expect(dummy.assert_positive_integer!({:val => 4}, :val)).to eq(4)
    end

    context "when no default value given" do
      context "when the value by the passed key is not integer" do
        it "converts non-integers to integers" do
          expect(dummy.assert_positive_integer!({:val => 4.4}, :val)).to eq(4)
        end

        it "changes the original value to the obtained integer" do
          h = {:val => 4.4}
          expect(dummy.assert_positive_integer!(h, :val)).to eq(4)
          expect(h[:val]).to eq(4)
        end

        it "raises exception if the original value cannot be converted to integer"do
          expect{ dummy.assert_positive_integer!({:val => :bad_int}, :val) }.to raise_exception(ArgumentError)
        end
      end

      it "raises exception if the value is not positive" do
        expect{ dummy.assert_positive_integer!({:val => -1}, :val) }.to raise_exception(ArgumentError)
      end

      it "raises exception if the value is not defined" do
        expect{ dummy.assert_positive_integer!({}, :val) }.to raise_exception(ArgumentError)
      end
    end

    context "when default value given" do
      it "prefers value from options to default" do
        expect(dummy.assert_positive_integer!({:val => 4}, :val, 22)).to eq(4)
      end

      it "uses default value when there is no one in options" do
        expect(dummy.assert_positive_integer!({}, :val, 22)).to eq(22)
      end

      it "checks default value if it is to be used" do
        expect{dummy.assert_positive_integer!({}, :val, :bad)}.to raise_exception(ArgumentError)
        expect{dummy.assert_positive_integer!({}, :val, -1)}.to raise_exception(ArgumentError)
      end
    end
  end

  describe "#assert_array!" do
    it "extracts value from hash by passed key" do
      expect(dummy.assert_array!({:val => [:foo]}, :val)).to eq([:foo])
    end

    context "when no default value given" do
      it "raises exception if th value is not an Array" do
        expect{ dummy.assert_array!({:val => :bad}, :val) }.to raise_exception(ArgumentError)
      end

      it "raises exception if the value is not defined" do
        expect{ dummy.assert_array!({}, :val) }.to raise_exception(ArgumentError)
      end
    end

    context "when default value given" do
      it "prefers value from options to default" do
        expect(dummy.assert_array!({:val => [:foo]}, :val, [])).to eq([:foo])
      end

      it "uses default value when there is no one in options" do
        expect(dummy.assert_array!({}, :val, [])).to eq([])
      end

      it "checks default value if it is to be used" do
        expect{dummy.assert_array!({}, :val, :bad)}.to raise_exception(ArgumentError)
      end
    end
  end

  describe "#assert_ranged_float!" do

    it "extracts float value from hash by passed key" do
      expect(dummy.assert_ranged_float!({:val => 4}, :val, 0, 100)).to be_generally_equal(4)
    end

    context "when the value by the passed key is not float" do
      it "converts non-floats to floats" do
        expect(dummy.assert_ranged_float!({:val => "4.0000"}, :val, 0, 100)).to be_generally_equal(4)
      end

      it "changes the original value to the obtained float" do
        h = {:val => "4.000"}
        expect(dummy.assert_ranged_float!(h, :val, 0, 100)).to be_generally_equal(4)
        expect(h[:val]).to be_generally_equal(4)
      end

      it "raises exception if the original value cannot be converted to float" do
        expect{ dummy.assert_ranged_float!({:val => :bad_float}, :val, 0, 100) }.to raise_exception(ArgumentError)
      end
    end

    it "raises exception if the value is not within range" do
      expect{ dummy.assert_ranged_float!({:val => -0.1}, :val, 0, 100) }.to raise_exception(ArgumentError)
      expect{ dummy.assert_ranged_float!({:val => 100.1}, :val, 0, 100) }.to raise_exception(ArgumentError)
    end

    it "raises exception if the value is not defined" do
      expect{ dummy.assert_ranged_float!({}, :val) }.to raise_exception(ArgumentError)
    end
  end

  describe "#uniqid" do
    it "returns uniq strings" do
      uniq_values = (1..1000).map{|_| dummy.uniqid}
      expect(uniq_values.uniq.count).to eq(uniq_values.count)
    end
  end

  describe "#titleize" do
    it "converts identificator to title" do
      expect(dummy.titleize("aaa_bbb")).to eq('Aaa Bbb')
      expect(dummy.titleize(:aaa_bbb)).to eq('Aaa Bbb')
      expect(dummy.titleize("aaa bbb")).to eq('Aaa Bbb')
    end
  end

  describe "#camelize" do
    it "camelizes string" do
      expect(dummy.camelize("aa_bb_cc")).to eq("aaBbCc")
      expect(dummy.camelize("aa_bb_cc", true)).to eq("AaBbCc")
    end
  end

  describe "#underscore" do
    it "underscores string" do
      expect(dummy.underscore("aaBbCc")).to eq("aa_bb_cc")
      expect(dummy.underscore("AaBbCc")).to eq("aa_bb_cc")
      expect(dummy.underscore("aaBb::Cc")).to eq("aa_bb/cc")
    end
  end

  describe "#camelize_keys" do
    it "deeply camelizes keys in hashes" do
      expect(dummy.camelize_keys({ :aa_bb_cc => [ { :dd_ee => 123 }, 456 ] })).to eq({ 'aaBbCc' => [ { 'ddEe' => 123 }, 456 ] })
    end
  end

  describe "#symbolize_keys" do
    it "converts symbolizable keys to symbols" do
      expect(dummy.symbolize_keys({"a" => 5, 6 => 7})).to eq({a: 5, 6 => 7})
    end
  end

  describe "#subsets_of" do
    it "returns all subsets of given array" do
      expect(dummy.subsets_of([1, 2]).sort).to eq([[], [1], [2], [1, 2]].sort)
    end
  end

  describe "#each_subset" do
    it "iterates over each subset" do
      subsets = []
      dummy.each_subset([1, 2]) {|s| subsets << s}
      expect(subsets.sort).to eq([[], [1], [2], [1, 2]].sort)
    end
  end

  describe '#parse_time' do
    context "when argument is a valid YYYYmmddHHMMSS string" do
      it "corrects Time object" do
        t = dummy.parse_time("19700101000000")
        expect(t).to be_kind_of(Time)
        expect(t.to_i).to eq(0)
      end
    end
    context "when argument is an invalid YYYYmmddHHMMSS string" do
      it "raises ArgumentError" do
        expect{ dummy.parse_time("19709901000000") }.to raise_exception(ArgumentError)
      end
    end
    context "when argument is not a YYYYmmddHHMMSS string" do
      it "raises ArgumentError" do
        expect{ dummy.parse_time("197099010000000") }.to raise_exception(ArgumentError)
      end
    end
  end
end
