require 'spec_helper'

describe PulseMeter::Sensor::Timelined::Average do
  it_should_behave_like "timeline sensor"
  it_should_behave_like "timelined subclass", [1, 2], 1.5
end
