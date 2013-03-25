Gem::Specification.new do |gem|
  gem.authors       = ['Taras Kunch']
  gem.email         = ['tkunch@rebbix.com']

  description       = 'Logger for Rails that sends data to fluentd'
  gem.description   = description
  gem.summary       = description

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.name          = 'rails-fluent-logging'
  gem.version       = '0.0.1'

  gem.add_dependency('active_support')
  gem.add_dependency('railties')
  gem.add_dependency('fluent-logger', '0.4.4')
end
