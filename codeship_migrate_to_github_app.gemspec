
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "codeship_migrate_to_github_app/version"

Gem::Specification.new do |spec|
  spec.name          = "codeship_migrate_to_github_app"
  spec.version       = CodeshipMigrateToGithubApp::VERSION
  spec.authors       = ["Codeship Engineering"]
  spec.email         = ["codeship-engineering@cloudbees.com"]

  spec.summary       = "Migrate your Codeship Projects from legacy Github services to Codeship's Github App"
  spec.description   = "Migrate your Codeship Projects from legacy Github services to Codeship's Github App"
  spec.homepage      = "https://github.com/codeship/codeship_migrate_to_github_app"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "cucumber", "~> 2.4.0"
  spec.add_development_dependency "aruba"

  spec.add_dependency "thor", "~> 0.20.0"
end
