# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module EpistemicVigilance
      module Helpers
        class Source
          include Constants

          attr_reader :id, :name, :domain, :claims_made, :claims_verified, :claims_refuted
          attr_accessor :reliability

          def initialize(name:, domain:)
            @id              = SecureRandom.uuid
            @name            = name
            @domain          = domain
            @reliability     = DEFAULT_SOURCE_RELIABILITY
            @claims_made     = 0
            @claims_verified = 0
            @claims_refuted  = 0
          end

          def record_verified!
            @claims_verified += 1
            @reliability = (@reliability + RELIABILITY_BOOST).clamp(0.0, 1.0)
          end

          def record_refuted!
            @claims_refuted += 1
            @reliability = (@reliability - RELIABILITY_PENALTY).clamp(0.0, 1.0)
          end

          def reliability_label
            SOURCE_RELIABILITY_LABELS.find { |range, _label| range.include?(@reliability) }&.last || :uncertain
          end

          def track_record
            @claims_verified / (@claims_verified + @claims_refuted + 1.0)
          end

          def to_h
            {
              id:                @id,
              name:              @name,
              domain:            @domain,
              reliability:       @reliability,
              reliability_label: reliability_label,
              claims_made:       @claims_made,
              claims_verified:   @claims_verified,
              claims_refuted:    @claims_refuted,
              track_record:      track_record
            }
          end
        end
      end
    end
  end
end
