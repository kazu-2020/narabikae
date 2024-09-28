require_relative "lib/narabikae/version"

Gem::Specification.new do |spec|
  spec.name        = "narabikae"
  spec.version     = Narabikae::VERSION
  spec.authors     = ["kazu-2020"]
  spec.email       = ["64774307+kazu-2020@users.noreply.github.com"]
  spec.homepage    = "https://todo.example.com"
  spec.summary     = "Narabikae."
  spec.description = "Narabikae."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://todo.example.com"
  spec.metadata["changelog_uri"] = "https://todo.example.com"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.3.2"
end
