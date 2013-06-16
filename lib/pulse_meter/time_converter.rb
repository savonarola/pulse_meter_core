require 'tzinfo'

module PulseMeter
  class TimeConverter
    def initialize(timezone_name)
      @tz = TZInfo::Timezone.get(timezone_name)
    rescue TZInfo::InvalidTimezoneIdentifier
      @tz = TZInfo::Timezone.get('UTC')
    end

    def to_redis(time)
      tz_period.to_local(time.to_i).to_i
    end

    def from_redis(time)
      tz_period.to_utc(time.to_i).to_i
    end

    private

    def tz_period
      @tz.period_for_utc(Time.now.utc)
    end

  end
end
