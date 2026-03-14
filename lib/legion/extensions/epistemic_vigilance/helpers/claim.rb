# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module EpistemicVigilance
      module Helpers
        class Claim
          include Constants

          attr_reader :id, :content, :source_id, :domain, :created_at,
                      :evidence_for, :evidence_against, :verdict
          attr_accessor :confidence

          def initialize(content:, source_id:, domain:, confidence: 0.5)
            @id               = SecureRandom.uuid
            @content          = content
            @source_id        = source_id
            @domain           = domain
            @confidence       = confidence.clamp(0.0, 1.0)
            @verdict          = :suspended
            @evidence_for     = 0
            @evidence_against = 0
            @created_at       = Time.now.utc
          end

          def support!
            @evidence_for += 1
            @confidence   = (@confidence + 0.05).clamp(0.0, 1.0)
          end

          def challenge!
            @evidence_against += 1
            @confidence       = (@confidence - 0.08).clamp(0.0, 1.0)
          end

          def credibility_ratio
            @evidence_for / (@evidence_for + @evidence_against + 1.0)
          end

          def contested?
            @evidence_against.positive? && credibility_ratio < 0.6
          end

          def well_supported?
            @evidence_for >= 3 && credibility_ratio > 0.7
          end

          def adjudicate!(verdict:)
            @verdict = verdict
          end

          def to_h
            {
              id:                @id,
              content:           @content,
              source_id:         @source_id,
              domain:            @domain,
              confidence:        @confidence,
              verdict:           @verdict,
              evidence_for:      @evidence_for,
              evidence_against:  @evidence_against,
              credibility_ratio: credibility_ratio,
              contested:         contested?,
              well_supported:    well_supported?,
              created_at:        @created_at
            }
          end
        end
      end
    end
  end
end
