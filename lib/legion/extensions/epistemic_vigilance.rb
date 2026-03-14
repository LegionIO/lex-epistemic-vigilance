# frozen_string_literal: true

require 'legion/extensions/epistemic_vigilance/version'
require 'legion/extensions/epistemic_vigilance/helpers/constants'
require 'legion/extensions/epistemic_vigilance/helpers/claim'
require 'legion/extensions/epistemic_vigilance/helpers/source'
require 'legion/extensions/epistemic_vigilance/helpers/vigilance_engine'
require 'legion/extensions/epistemic_vigilance/runners/epistemic_vigilance'

module Legion
  module Extensions
    module EpistemicVigilance
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
