# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'beanstream'
  s.version     = '1.1.0'
  s.date        = '2015-11-19'
  s.summary     = 'Beanstream Ruby SDK'
  s.description = 'Accept payments using Beanstream and Ruby'
  s.authors     = ['Brent Owens', 'Colin Walker', 'Tom Mengda']
  s.email       = 'bowens@beanstream.com'
  s.homepage    = 'https://dev.na.bambora.com/docs/'
  s.license     = 'MIT'

  paths_to_names = ->(paths) { paths.map { |f| File.basename(f) } }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.executables   = paths_to_names.call(`git ls-files -- bin/*`.split("\n"))
  s.require_paths = ['lib']

  s.add_dependency('json', '~> 2.1.0')
  s.add_dependency('rest-client', '~> 2.0')

  s.add_development_dependency('rspec')
  s.add_development_dependency('rubocop')
end
