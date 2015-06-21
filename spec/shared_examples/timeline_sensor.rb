shared_examples_for "timeline sensor" do |extra_init_values, default_event|
  class Dummy
    include PulseMeter::Mixins::Dumper
    def name; :dummy end
    def redis; PulseMeter.redis; end
  end

  let(:name){ :some_value_with_history }
  let(:ttl){ 10000 }
  let(:raw_data_ttl){ 3000 }
  let(:interval){ 5 }
  let(:reduce_delay){ 3 }
  let(:timezone){'Europe/Moscow'}
  let(:good_init_values){ {:timezone => timezone, :ttl => ttl, :raw_data_ttl => raw_data_ttl, :interval => interval, :reduce_delay => reduce_delay}.merge(extra_init_values || {}) }
  let!(:sensor){ described_class.new(name, good_init_values) }
  let(:dummy) {Dummy.new}
  let(:base_class){ PulseMeter::Sensor::Base }
  let(:redis){ PulseMeter.redis }
  let(:sample_event) {default_event || 123}

  before(:each) do
    @now = Time.now
    tc = PulseMeter::TimeConverter.new(timezone)

    @redis_now = tc.to_redis(@now).to_i

    @interval_id = (@redis_now / interval) * interval
    @prev_interval_id = (@redis_now / interval) * interval - interval

    @raw_data_key = sensor.raw_data_key(@interval_id)

    @prev_raw_data_key = sensor.raw_data_key(@prev_interval_id)

    @next_raw_data_key = sensor.raw_data_key(@interval_id + interval)

    @start_of_interval = Time.at(tc.from_redis(@interval_id))
    @start_of_prev_interval = Time.at(tc.from_redis(@prev_interval_id))
  end

  describe "#dump" do
    it "is dumped succesfully" do
      expect {sensor.dump!}.not_to raise_exception
    end
  end

  describe ".restore" do
    before do
      # no need to call sensor.dump! explicitly for it
      # will be called automatically after creation
      @restored = base_class.restore(sensor.name)
    end

    it "restores #{described_class} instance" do
      expect(@restored).to be_instance_of(described_class)
    end

    it "restores object with the same data" do
      def inner_data(obj)
        obj.instance_variables.sort.map {|v| obj.instance_variable_get(v)}
      end

      expect(inner_data(sensor)).to eq(inner_data(@restored))
    end
  end

  describe "#event" do
    it "writes events to redis" do
      expect{
        sensor.event(sample_event)
      }.to change{ redis.keys('*').count }.by(1)
    end

    it "writes data so that it totally expires after :raw_data_ttl" do
      key_count = redis.keys('*').count
      sensor.event(sample_event)
      Timecop.freeze(@now + raw_data_ttl + 1) do
        expect(redis.keys('*').count).to eq(key_count)
      end
    end

    it "writes data to bucket indicated by truncated timestamp" do
      expect{
        Timecop.freeze(@start_of_interval) do
          sensor.event(sample_event)
        end
      }.to change{ redis.ttl(@raw_data_key) }
    end

    it "returns true if event processed correctly" do
      expect(sensor.event(sample_event)).to be
    end

    it "catches StandardErrors and returns false" do
      allow(sensor).to receive(:aggregate_event) {raise StandardError}
      expect(sensor.event(sample_event)).not_to be
    end
  end

  describe "#event_at" do
    let(:now) {@now}
    it "writes events to redis" do
      expect{
          sensor.event_at(now, sample_event)
      }.to change{ redis.keys('*').count }.by(1)
    end

    it "writes data so that it totally expires after :raw_data_ttl" do
      key_count = redis.keys('*').count
      sensor.event_at(now, sample_event)
      Timecop.freeze(now + raw_data_ttl + 1) do
        expect(redis.keys('*').count).to eq(key_count)
      end
    end

    it "writes data to bucket indicated by passed time" do
      expect{
        Timecop.freeze(@start_of_interval) do
          sensor.event_at(@start_of_prev_interval, sample_event)
        end
      }.to change{ redis.ttl(@prev_raw_data_key) }
    end
  end

  describe "#summarize" do
    it "converts data stored by raw_data_key to a value defined only by stored data" do
      Timecop.freeze(@start_of_interval) do
        sensor.event(sample_event)
      end
      Timecop.freeze(@start_of_interval + interval) do
        sensor.event(sample_event)
      end
      expect(sensor.summarize(@raw_data_key)).to eq(sensor.summarize(@next_raw_data_key))
      expect(sensor.summarize(@raw_data_key)).not_to be_nil
    end
  end

  describe "#reduce" do
    it "stores summarized value into data_key" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      val = sensor.summarize(@raw_data_key)
      expect(val).not_to be_nil
      sensor.reduce(@interval_id)
      expect(redis.get(sensor.data_key(@interval_id))).to eq(val.to_s)
    end

    it "removes original raw_data_key" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      expect{
        sensor.reduce(@interval_id)
      }.to change{ redis.keys(sensor.raw_data_key(@interval_id)).count }.from(1).to(0)
    end

    it "expires stored summarized data" do
      Timecop.freeze(@start_of_interval) do
        sensor.event(sample_event)
        sensor.reduce(@interval_id)
        expect(redis.keys(sensor.data_key(@interval_id)).count).to eq(1)
      end
      Timecop.freeze(@start_of_interval + ttl + 1) do
        expect(redis.keys(sensor.data_key(@interval_id)).count).to eq(0)
      end
    end

    it "does not store data if there is no corresponding raw data" do
      Timecop.freeze(@start_of_interval) do
        sensor.reduce(@interval_id)
        expect(redis.keys(sensor.data_key(@interval_id)).count).to eq(0)
      end
    end

    it "does not store summarized data if it already exists" do
      data_key = sensor.data_key(@interval_id)
      redis.set(data_key, :dummy)
      Timecop.freeze(@start_of_interval) do
        sensor.event(sample_event)
        sensor.reduce(@interval_id)
        expect(redis.get(data_key)).to eq("dummy")
      end
    end
  end

  describe "#reduce_all_raw" do
    it "reduces all data older than reduce_delay" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      val0 = sensor.summarize(@raw_data_key)
      Timecop.freeze(@start_of_interval + interval){ sensor.event(sample_event) }
      val1 = sensor.summarize(@next_raw_data_key)
      expect{
        Timecop.freeze(@start_of_interval + interval + interval + reduce_delay + 1) do
          sensor.reduce_all_raw
        end
      }.to change{ redis.keys(sensor.raw_data_key('*')).count }.from(2).to(0)

      expect(redis.get(sensor.data_key(@interval_id))).to eq(val0.to_s)
      expect(redis.get(sensor.data_key(@interval_id + interval))).to eq(val1.to_s)
    end

    it "creates up to MAX_INTERVALS compresed data pieces from previously uncompressed data" do
      max_count = described_class::MAX_INTERVALS
      start = @start_of_interval - reduce_delay - max_count * interval
      (max_count + 100).times do |i|
        Timecop.freeze(start + i * interval) {sensor.event(sample_event)}
      end

      Timecop.freeze(@start_of_interval) do
        expect {
          sensor.reduce_all_raw
        }.to change {redis.keys(sensor.data_key('*')).count}.from(0).to(max_count)
      end
    end

    it "does not reduce fresh data" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }

      expect{
        Timecop.freeze(@start_of_interval + interval + reduce_delay - 1) { sensor.reduce_all_raw }
      }.not_to change{ redis.keys(sensor.raw_data_key('*')).count }

      expect{
        Timecop.freeze(@start_of_interval + interval + reduce_delay - 1) { sensor.reduce_all_raw }
      }.not_to change{ redis.keys(sensor.data_key('*')).count }
    end
  end

  describe ".reduce_all_raw" do
    it "silently skips objects without reduce logic" do
      dummy.dump!
      expect {described_class.reduce_all_raw}.not_to raise_exception
    end

    it "sends reduce_all_raw to all dumped objects" do
      expect_any_instance_of(described_class).to receive(:reduce_all_raw)
      described_class.reduce_all_raw
    end
  end

  describe "#timeline_within" do
    it "raises exception unless both arguments are Time objects" do
      [:q, nil, -1].each do |bad_value|
        expect{ sensor.timeline_within(@now, bad_value) }.to raise_exception(ArgumentError)
        expect{ sensor.timeline_within(bad_value, @now) }.to raise_exception(ArgumentError)
      end
    end

    it "returns an array of SensorData objects corresponding to stored data for passed interval" do
      sensor.event(sample_event)
      now = @now
      timeline = sensor.timeline_within(now - 1, now)
      expect(timeline).to be_kind_of(Array)
      timeline.each{|i| expect(i).to be_kind_of(SensorData) }
    end

    it "returns array of results containing as many results as there are sensor interval beginnings in the passed interval" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      Timecop.freeze(@start_of_interval + interval){ sensor.event(sample_event) }

      future = @start_of_interval + 3600
      Timecop.freeze(future) do
        expect(sensor.timeline_within(
          Time.at(@start_of_interval + interval - 1),
          Time.at(@start_of_interval + interval + 1)
        ).size).to eq(1)

        expect(sensor.timeline_within(
          Time.at(@start_of_interval - 1),
          Time.at(@start_of_interval + interval + 1)
        ).size).to eq(2)
      end

      Timecop.freeze(@start_of_interval + interval + 2) do
        expect(sensor.timeline_within(
          Time.at(@start_of_interval + interval + 1),
          Time.at(@start_of_interval + interval + 2)
        ).size).to eq(0)
      end
    end

    context "to avoid getting to much data" do
      let(:max) {PulseMeter::Sensor::Timeline::MAX_TIMESPAN_POINTS}

      it "skips some points not to exceed MAX_TIMESPAN_POINTS" do
        count = max * 2
        expect(sensor.timeline_within(
          Time.at(@start_of_interval - 1),
          Time.at(@start_of_interval + count * interval)
        ).size).to be < max
      end

      it "does not skip any points when timeline orginal size is less then MAX_TIMESPAN_POINTS" do
        count = max - 1
        expect(sensor.timeline_within(
          Time.at(@start_of_interval - 1),
          Time.at(@start_of_interval + count * interval)
        ).size).to eq(count)
      end

      it "does give full data in case skip_optimization parameter set to true" do
        count = max * 2
        expect(sensor.timeline_within(
          Time.at(@start_of_interval - 1),
          Time.at(@start_of_interval + count * interval),
          true
        ).size).to eq(count)
      end
    end
  end

  describe "#timeline" do
    it "raises exception if passed interval is not a positive integer" do
      [:q, nil, -1].each do |bad_interval|
        expect{ sensor.timeline(bad_interval) }.to raise_exception(ArgumentError)
      end
    end

    it "requests timeline within interval from given number of seconds ago till now" do
      Timecop.freeze(@now) do
        now = @now
        ago = interval * 100
        expect(sensor.timeline(ago)).to eq(sensor.timeline_within(now - ago, now))
      end
    end

    it "returns array of results containing as many results as there are sensor interval beginnings in the passed interval" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      Timecop.freeze(@start_of_interval + interval){ sensor.event(sample_event) }

      Timecop.freeze(@start_of_interval + interval + 1) do
        expect(sensor.timeline(2).size).to eq(1)
      end
      Timecop.freeze(@start_of_interval + interval + 2) do
        expect(sensor.timeline(1).size).to eq(0)
      end
      Timecop.freeze(@start_of_interval + interval + 1) do
        expect(sensor.timeline(2 + interval).size).to eq(2)
      end
    end
  end

  describe "#drop_within" do
    it "raises exception unless both arguments are Time objects" do
      [:q, nil, -1].each do |bad_value|
        expect{ sensor.drop_within(@now, bad_value) }.to raise_exception(ArgumentError)
        expect{ sensor.drop_within(bad_value, @now) }.to raise_exception(ArgumentError)
      end
    end

    it "drops as many raw results as there are sensor interval beginnings in the passed interval" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      Timecop.freeze(@start_of_interval + interval){ sensor.event(sample_event) }

      future = @start_of_interval + interval * 3
      Timecop.freeze(future) do
        expect(sensor.drop_within(
          Time.at(@start_of_interval + interval - 1),
            Time.at(@start_of_interval + interval + 1)
        )).to eq(1)

        data = sensor.timeline_within(
          Time.at(@start_of_interval + interval - 1),
            Time.at(@start_of_interval + interval + 1)
        )
        expect(data.size).to eq(1)
        expect(data.first.value).to be_nil # since data is dropped

      end

      Timecop.freeze(@start_of_interval + interval + 2) do
        expect(sensor.drop_within(
          Time.at(@start_of_interval + interval + 1),
            Time.at(@start_of_interval + interval + 2)
        )).to eq(0)
      end
    end

    it "drops as many reduced results as there are sensor interval beginnings in the passed interval" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      Timecop.freeze(@start_of_interval + interval){ sensor.event(sample_event) }

      future = @start_of_interval
      Timecop.freeze(future) do
        sensor.reduce_all_raw
        expect(sensor.drop_within(
          Time.at(@start_of_interval + interval - 1),
            Time.at(@start_of_interval + interval + 1)
        )).to eq(1)

        data = sensor.timeline_within(
          Time.at(@start_of_interval + interval - 1),
            Time.at(@start_of_interval + interval + 1)
        )
        expect(data.size).to eq(1)
        expect(data.first.value).to be_nil # since data is dropped

      end

      Timecop.freeze(@start_of_interval + interval + 2) do
        expect(sensor.drop_within(
          Time.at(@start_of_interval + interval + 1),
            Time.at(@start_of_interval + interval + 2)
        )).to eq(0)
      end
    end
  end

  describe "SensorData value for an interval" do
    def check_sensor_data(sensor, value)
      data = sensor.timeline(2).first
      expect(data.value).to be_generally_equal(sensor.deflate_safe(value))
      expect(data.start_time.to_i).to eq(@start_of_interval.to_i)
    end

    it "contains summarized value stored by data_key for reduced intervals" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      sensor.reduce(@interval_id)
      Timecop.freeze(@start_of_interval + 1){
        check_sensor_data(sensor, redis.get(sensor.data_key(@interval_id)))
      }
    end

    it "contains summarized value based on raw data for intervals not yet reduced" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      Timecop.freeze(@start_of_interval + 1){
        check_sensor_data(sensor, sensor.summarize(@raw_data_key))
      }
    end

    it "contains nil for intervals without any data" do
      Timecop.freeze(@start_of_interval + 1) {
        check_sensor_data(sensor, nil)
      }
    end
  end

  describe "#cleanup" do
    it "removes all sensor data (raw data, reduced data, annotations) from redis" do
      Timecop.freeze(@start_of_interval){ sensor.event(sample_event) }
      sensor.reduce(@interval_id)
      Timecop.freeze(@start_of_interval + interval){ sensor.event(sample_event) }
      sensor.annotate("Fooo sensor")

      sensor.cleanup
      expect(redis.keys('*')).to be_empty
    end
  end

end
