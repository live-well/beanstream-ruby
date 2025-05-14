# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'beanstream'
  s.version     = '2.0.1'
  s.date        = '2025-05-13'
  s.summary     = 'Beanstream Ruby SDK'
  s.description = 'Accept payments using Beanstream and Ruby'
  s.authors     = ['Brent Owens', 'Colin Walker', 'Tom Mengda']
  s.email       = 'bowens@beanstream.com'
  s.homepage    = 'https://dev.na.bambora.com/docs/'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.3.0'

  paths_to_names = ->(paths) { paths.map { |f| File.basename(f) } }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.executables   = paths_to_names.call(`git ls-files -- bin/*`.split("\n"))
  s.require_paths = ['lib']

  s.add_dependency('json', '~> 2.6.3')
  s.add_dependency('rest-client', '~> 2.0')

  s.add_development_dependency('rspec', '~> 3.12.0')
  s.add_development_dependency('rubocop', '~> 1.60.0')
end
