# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["Ilya Averyanov", "Sergey Averyanov"]
  gem.email         = ["av@fun-box.ru", "averyanov@gmail.com"]
  gem.description   = %q{Lightweight metrics processor}
  gem.summary       = %q{
    Lightweight Redis-based metrics aggregator and processor
    with simple CLI interface
  }
  gem.homepage      = "https://github.com/savonarola/pulse_meter_core"

  gem.required_ruby_version = '>= 1.9.2'
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pulse_meter_core"
  gem.require_paths = ["lib"]
  gem.version       = "0.4.13"

  gem.add_runtime_dependency('json')
  gem.add_runtime_dependency('redis')
  gem.add_runtime_dependency('tzinfo')

  gem.add_development_dependency('aquarium')
  gem.add_development_dependency('hashie')
  gem.add_development_dependency('mock_redis')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('redcarpet')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('simplecov')
  gem.add_development_dependency('timecop')
  gem.add_development_dependency('yard')

end
