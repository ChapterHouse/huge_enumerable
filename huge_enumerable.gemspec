# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'huge_enumerable/version'

Gem::Specification.new do |spec|
  spec.name          = "huge_enumerable"
  spec.version       = HugeEnumerable::VERSION
  spec.authors       = ["Frank Hall"]
  spec.email         = ["ChapterHouse.Dune@gmail.com"]

  spec.description   = %q{Enumerate, sample, shuffle, combine, permutate, and create products of massive data sets using minimal memory}
  spec.summary       = %q{Enumerate, sample, shuffle, combine, permutate, and create products of massive data sets using minimal memory}
  spec.homepage      = "https://github.com/ChapterHouse/#{spec.name}"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ChapterHouse/#{spec.name}/tree/v#{spec.version}"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "prime_miller_rabin", '~> 0.1', '>= 0.1.0'

  spec.add_development_dependency 'bundler', '~> 2.3'
  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rdoc', '~> 6.4'

end
