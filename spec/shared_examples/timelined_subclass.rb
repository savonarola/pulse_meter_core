shared_examples_for "timelined subclass" do |events, result|
  let(:name){ :counter }
  let(:ttl){ 100 }
  let(:raw_data_ttl){ 10 }
  let(:interval){ 5 }
  let(:reduce_delay){ 3 }
  let(:init_values){ {:ttl => ttl, :raw_data_ttl => raw_data_ttl, :interval => interval, :reduce_delay => reduce_delay} }
  let(:sensor){ described_class.new(name, init_values) }
  let(:epsilon) {1}

  it "should calculate summarized value" do
    interval_id = 0
    start_of_interval = Time.at(interval_id)
    Timecop.freeze(start_of_interval) do
      events.each {|e| sensor.event(e)}
    end
    Timecop.freeze(start_of_interval + interval) do
      data = sensor.timeline(interval + epsilon).first
      data.value.should == result
    end
  end

end