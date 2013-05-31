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
  spec.homepage      = "https://github.com/ChapterHouse/huge_enumerable.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec', '~> 2.13'
  spec.add_runtime_dependency "backports" # Wish this could be conditional. It is only used for ruby 1.8 for as long as I support it.

end
