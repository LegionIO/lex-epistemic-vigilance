# frozen_string_literal: true

require 'legion/extensions/epistemic_vigilance/helpers/constants'
require 'legion/extensions/epistemic_vigilance/helpers/claim'
require 'legion/extensions/epistemic_vigilance/helpers/source'
require 'legion/extensions/epistemic_vigilance/helpers/vigilance_engine'
require 'legion/extensions/epistemic_vigilance/runners/epistemic_vigilance'

module Legion
  module Extensions
    module EpistemicVigilance
      class Client
        include Runners::EpistemicVigilance

        private

        def engine
          @engine ||= Helpers::VigilanceEngine.new
        end
      end
    end
  end
end
