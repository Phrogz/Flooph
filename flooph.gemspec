# encoding: UTF-8
require_relative 'flooph'

Gem::Specification.new do |s|
  s.name        = "Flooph"
  s.version     = Flooph::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Gavin Kistner"]
  s.email       = ["gavin@phrogz.net"]
  s.license     = "MIT"
  s.summary     = %q{A template markup and evaluator designed to be simple and safe from malicious input.}
  s.description = %q{
    Flooph is a Ruby library designed to let you take code from (possibly-malicious) users and evaluate it safely.
    Instead of evaluating arbitrary Ruby code (or JavaScript, or any other interpreter), it specifies a custom 'language', with its own parser and evaluation.

    Flooph provides four core pieces of functionality:

    * A simple syntax for specifying key/value pairs (much like a Ruby Hash literal).
    * A simple template language that supports conditional content and injecting content.
    * Standalone functionality for evaluating conditional expressions based on the key/values (also used in the templates).
    * Standalone functionality for evaluating value expressions based on the key/values (also used in the templates).
  }
  s.homepage    = "https://github.com/Phrogz/Flooph"
  s.add_runtime_dependency "parslet", '~> 1.8'
  s.files         = ["flooph.rb"]
end