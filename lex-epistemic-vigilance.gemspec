# frozen_string_literal: true

require_relative 'lib/legion/extensions/epistemic_vigilance/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-epistemic-vigilance'
  spec.version       = Legion::Extensions::EpistemicVigilance::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Epistemic Vigilance'
  spec.description   = 'Epistemic vigilance engine for brain-modeled agentic AI — source reliability, claim consistency, and belief coherence evaluation'
  spec.homepage      = 'https://github.com/LegionIO/lex-epistemic-vigilance'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-epistemic-vigilance'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-epistemic-vigilance'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-epistemic-vigilance'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-epistemic-vigilance/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-epistemic-vigilance.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
