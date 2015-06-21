require "spec_helper"

describe PulseMeter::Sensor::Configuration do
  let(:counter_config) {
    {
      cnt: {
        sensor_type: 'counter',
        args: {
          annotation: "MySensor"
        }
      },
    }
  }

  describe "#add_sensor" do
    let(:cfg) {described_class.new}

    it "creates sensor available under passed name" do
      expect(cfg.has_sensor?(:foo)).not_to be
      cfg.add_sensor(:foo, sensor_type: 'counter')
      expect(cfg.has_sensor?(:foo)).not_to be
    end

    it "has event shortcut for the sensor" do
      cfg.add_sensor(:foo, sensor_type: 'counter')
      puts cfg.to_yaml
      cfg.sensor(:foo){|s| expect(s).to receive(:event).with(321)}
      cfg.foo(321)
    end

    it "has event_at shortcut for the sensor" do
      cfg.add_sensor(:foo, sensor_type: 'counter')
      now = Time.now
      cfg.sensor(:foo) do |sensor|
        expect(sensor).to receive(:event_at).with(now, 321)
      end
      cfg.foo_at(now, 321)
    end

    it "creates sensor with correct type" do
      cfg.add_sensor(:foo, sensor_type: 'counter')
      cfg.sensor(:foo){|s| expect(s).to be_kind_of(PulseMeter::Sensor::Counter)}
    end

    it "does not raise exception if sensor type is bad" do
      expect{ cfg.add_sensor(:foo, sensor_type: 'baaaar') }.not_to raise_exception
    end

    it "passes args to created sensor" do
      cfg.add_sensor(:foo, sensor_type: 'counter', args: {annotation: "My Foo Counter"} )
      cfg.sensor(:foo){|s| expect(s.annotation).to eq("My Foo Counter") }
    end

    it "accepts hashie-objects" do
      class Dummy
        def sensor_type
          'counter'
        end
        def args
          Hashie::Mash.new(annotation: "My Foo Counter")
        end
      end

      cfg.add_sensor(:foo, Dummy.new)
      cfg.sensor(:foo){|s| expect(s.annotation).to eq("My Foo Counter")}
    end
  end

  describe ".new" do
    it "adds passed sensor setting hash using keys as names" do
      opts = {
        cnt: {
          sensor_type: 'counter'
        },
        ind: {
          sensor_type: 'indicator'
        }
      }
      cfg1 = described_class.new(opts)
      cfg2 = described_class.new
      opts.each{|k,v| cfg2.add_sensor(k, v)}
      expect(cfg1.sensors.to_yaml).to eq(cfg2.sensors.to_yaml)
    end
  end

  describe "#sensor" do
    it "gives access to added sensors via block" do
      cfg = described_class.new(counter_config)
      cfg.sensor(:cnt){ |s| expect(s.annotation).to eq("MySensor") }
      cfg.sensor("cnt"){ |s| expect(s.annotation).to eq("MySensor") }
    end
  end

  describe "#each_sensor" do
    it "yields block for each name/sensor pair" do
      cfg = described_class.new(counter_config)
      sensors = {}
      cfg.each {|s| sensors[s.name.to_sym] = s}
      sensor = cfg.sensor(:cnt){|s| s}
      expect(sensors).to eq({:cnt => sensor})
    end
  end
end
