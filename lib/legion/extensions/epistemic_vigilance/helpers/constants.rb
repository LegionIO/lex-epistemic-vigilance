# frozen_string_literal: true

module Legion
  module Extensions
    module EpistemicVigilance
      module Helpers
        module Constants
          VIGILANCE_LEVELS = %i[trusting cautious skeptical hostile].freeze
          VIGILANCE_THRESHOLDS = { trusting: 0.8, cautious: 0.6, skeptical: 0.3, hostile: 0.0 }.freeze
          CLAIM_VERDICTS = %i[accepted provisionally_accepted suspended rejected].freeze
          SOURCE_RELIABILITY_LABELS = {
            (0.8..)     => :highly_reliable,
            (0.6...0.8) => :reliable,
            (0.4...0.6) => :uncertain,
            (0.2...0.4) => :unreliable,
            (..0.2)     => :deceptive
          }.freeze

          MAX_CLAIMS               = 200
          MAX_SOURCES              = 100
          MAX_HISTORY              = 500
          DEFAULT_SOURCE_RELIABILITY = 0.5
          RELIABILITY_BOOST        = 0.05
          RELIABILITY_PENALTY      = 0.1
          CONSISTENCY_WEIGHT       = 0.3
          SOURCE_WEIGHT            = 0.4
          COHERENCE_WEIGHT         = 0.3
          DECAY_RATE               = 0.01
        end
      end
    end
  end
end
