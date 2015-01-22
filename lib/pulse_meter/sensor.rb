require 'pulse_meter/sensor/base'
require 'pulse_meter/sensor/configuration'
require 'pulse_meter/sensor/counter'
require 'pulse_meter/sensor/indicator'
require 'pulse_meter/sensor/hashed_counter'
require 'pulse_meter/sensor/hashed_indicator'
require 'pulse_meter/sensor/multi'
require 'pulse_meter/sensor/uniq_counter'
require 'pulse_meter/sensor/timeline_reduce'
require 'pulse_meter/sensor/timeline'
require 'pulse_meter/sensor/timelined/average'
require 'pulse_meter/sensor/timelined/counter'
require 'pulse_meter/sensor/timelined/indicator'
require 'pulse_meter/sensor/timelined/hashed_counter'
require 'pulse_meter/sensor/timelined/hashed_indicator'
require 'pulse_meter/sensor/timelined/zset_based'
require 'pulse_meter/sensor/timelined/min'
require 'pulse_meter/sensor/timelined/max'
require 'pulse_meter/sensor/timelined/percentile'
require 'pulse_meter/sensor/timelined/multi_percentile'
require 'pulse_meter/sensor/timelined/median'
require 'pulse_meter/sensor/timelined/uniq_counter'

# Top level sensor module
module PulseMeter

  # Atomic sensor data
  SensorData = Struct.new(:start_time, :value)

  # General sensor exception
  class SensorError < StandardError; end

  # Exception to be raised when sensor name is malformed
  class BadSensorName < SensorError
    def initialize(name, options = {})
      super("Bad sensor name: `#{name}', only a-z letters, @ and _ are allowed")
    end
  end

  # Exception to be raised when Redis is not initialized
  class RedisNotInitialized < SensorError
    def initialize
      super("PulseMeter.redis is not set")
    end
  end

  # Exception to be raised when sensor cannot be dumped
  class DumpError < SensorError; end

  # Exception to be raised on attempts of using the same key for different sensors
  class DumpConflictError < DumpError; end

  # Exception to be raised when sensor cannot be restored
  class RestoreError < SensorError; end

  module Remote
    class MessageTooLarge < PulseMeter::SensorError; end
    class ConnectionError < PulseMeter::SensorError; end
  end
end
  
