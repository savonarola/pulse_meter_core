require 'rubygems'
require 'simplecov'
SimpleCov.start

$:.unshift File.expand_path('../../lib/', __FILE__)

ROOT = File.expand_path('../..', __FILE__)

Bundler.require(:default, :test, :development)


require 'pulse_meter_core'
PulseMeter.redis = MockRedis.new

Dir['spec/support/**/*.rb'].each{|f| require File.join(ROOT, f) }
Dir['spec/shared_examples/**/*.rb'].each{|f| require File.join(ROOT,f)}


require 'aquarium'
include Aquarium::Aspects

Aspect.new :after, :calls_to => [:event, :event_at], :for_types => [PulseMeter::Sensor::Base, PulseMeter::Sensor::Timeline] do |jp, obj, *args|
  PulseMeter.command_aggregator.wait_for_pending_events
end

PulseMeter.command_aggregator.max_queue_length = 20

RSpec.configure do |config|
  config.before(:each) do
    PulseMeter.redis = MockRedis.new
    Timecop.return
    PulseMeter.logger = Logger.new("/dev/null")
  end
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.include(Matchers)
end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false

