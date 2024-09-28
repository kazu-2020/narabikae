require_relative 'lib/narabikae/version'

Gem::Specification.new do |spec|
  spec.name        = 'narabikae'
  spec.version     = Narabikae::VERSION
  spec.authors     = ['matazou']
  spec.email       = ['64774307+kazu-2020@users.noreply.github.com']
  spec.homepage    = 'https://github.com/kazu-2020/narabikae'
  spec.summary     = 'provides simple position management and sorting functionality for Active Record in Rails.'
  spec.description = <<~DESCRIPTION
    provides functionality similar to acts_as_list. However, by managing position using a fractional indexing system, it allows database record updates during reordering to be completed with only a single update (N = 1)!
  DESCRIPTION
  spec.license = 'MIT'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['changelog_uri']   = 'https://github.com/kazu-2020/narabikae/releases'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/kazu-2020/narabikae/issues'
  spec.metadata['source_code_uri'] = 'https://github.com/kazu-2020/narabikae'

  spec.metadata['allowed_push_host']     = 'https://rubygems.org/'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{lib}/**/*', 'MIT-LICENSE', 'README.md']
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '~> 7.1', '>= 7.1.3.2'
  spec.add_dependency 'rspec-rails', '>= 5.0.0'
end
