# frozen_string_literal: true

module Legion
  module Extensions
    module EpistemicVigilance
      module Helpers
        class Client
          include Runners::EpistemicVigilance

          private

          def engine
            @engine ||= VigilanceEngine.new
          end
        end
      end
    end
  end
end
