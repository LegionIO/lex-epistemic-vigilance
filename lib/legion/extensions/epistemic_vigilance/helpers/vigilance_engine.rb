# frozen_string_literal: true

module Legion
  module Extensions
    module EpistemicVigilance
      module Helpers
        class VigilanceEngine
          include Constants

          def initialize
            @sources = {}
            @claims  = {}
          end

          def register_source(name:, domain:)
            source = Source.new(name: name, domain: domain)
            @sources[source.id] = source
            source.to_h
          end

          def submit_claim(content:, source_id:, domain:, initial_confidence: 0.5)
            source = @sources[source_id]
            return { error: :source_not_found } unless source

            claim = Claim.new(content: content, source_id: source_id, domain: domain,
                              confidence: initial_confidence)
            source.instance_variable_set(:@claims_made, source.claims_made + 1)
            @claims[claim.id] = claim
            assessment = assess_claim(claim_id: claim.id)
            { claim: claim.to_h, assessment: assessment }
          end

          def assess_claim(claim_id:)
            claim = @claims[claim_id]
            return { error: :claim_not_found } unless claim

            source        = @sources[claim.source_id]
            source_score  = build_source_score(source)
            consist_score = claim.credibility_ratio * CONSISTENCY_WEIGHT
            coher_score   = domain_coherence_score(claim.domain, exclude_id: claim_id)
            total         = source_score + consist_score + coher_score
            verdict       = recommended_verdict(total)

            {
              claim_id:            claim_id,
              source_score:        source_score,
              consistency_score:   consist_score,
              coherence_score:     coher_score,
              total_score:         total,
              recommended_verdict: verdict
            }
          end

          def support_claim(claim_id:)
            claim  = @claims[claim_id]
            source = claim && @sources[claim.source_id]
            return { error: :claim_not_found } unless claim

            claim.support!
            source&.record_verified!
            { claim_id: claim_id, confidence: claim.confidence, evidence_for: claim.evidence_for }
          end

          def challenge_claim(claim_id:)
            claim  = @claims[claim_id]
            source = claim && @sources[claim.source_id]
            return { error: :claim_not_found } unless claim

            claim.challenge!
            source&.record_refuted!
            { claim_id: claim_id, confidence: claim.confidence, evidence_against: claim.evidence_against }
          end

          def adjudicate_claim(claim_id:, verdict:)
            claim  = @claims[claim_id]
            source = claim && @sources[claim.source_id]
            return { error: :claim_not_found } unless claim

            claim.adjudicate!(verdict: verdict)
            update_source_on_adjudication(source, verdict)
            { claim_id: claim_id, verdict: verdict }
          end

          def source_reliability(source_id:)
            source = @sources[source_id]
            return { error: :source_not_found } unless source

            { source_id: source_id, reliability: source.reliability, label: source.reliability_label }
          end

          def contested_claims
            @claims.values.select(&:contested?).map(&:to_h)
          end

          def claims_by_source(source_id:)
            @claims.values.select { |c| c.source_id == source_id }.map(&:to_h)
          end

          def claims_by_domain(domain:)
            @claims.values.select { |c| c.domain == domain }.map(&:to_h)
          end

          def domain_vigilance_level(domain:)
            domain_claims = @claims.values.select { |c| c.domain == domain }
            return :skeptical if domain_claims.empty?

            avg = domain_claims.sum(&:confidence) / domain_claims.size.to_f
            level_for_score(avg)
          end

          def decay_all
            @claims.each_value do |claim|
              claim.confidence = (claim.confidence - DECAY_RATE).clamp(0.0, 1.0)
            end
            { decayed: @claims.size }
          end

          def prune_rejected
            before = @claims.size
            @claims.reject! { |_, c| c.verdict == :rejected && c.confidence < 0.1 }
            { pruned: before - @claims.size, remaining: @claims.size }
          end

          def to_h
            {
              sources_count: @sources.size,
              claims_count:  @claims.size,
              contested:     contested_claims.size,
              by_verdict:    verdict_counts
            }
          end

          private

          def build_source_score(source)
            return DEFAULT_SOURCE_RELIABILITY * SOURCE_WEIGHT unless source

            source.reliability * SOURCE_WEIGHT
          end

          def domain_coherence_score(domain, exclude_id:)
            peers = @claims.values.reject { |c| c.id == exclude_id }.select { |c| c.domain == domain }
            return 0.0 if peers.empty?

            avg = peers.sum(&:confidence) / peers.size.to_f
            avg * COHERENCE_WEIGHT
          end

          def recommended_verdict(total_score)
            if total_score >= VIGILANCE_THRESHOLDS[:trusting]
              :accepted
            elsif total_score >= VIGILANCE_THRESHOLDS[:cautious]
              :provisionally_accepted
            elsif total_score >= VIGILANCE_THRESHOLDS[:skeptical]
              :suspended
            else
              :rejected
            end
          end

          def level_for_score(score)
            if score >= VIGILANCE_THRESHOLDS[:trusting]
              :trusting
            elsif score >= VIGILANCE_THRESHOLDS[:cautious]
              :cautious
            elsif score >= VIGILANCE_THRESHOLDS[:skeptical]
              :skeptical
            else
              :hostile
            end
          end

          def update_source_on_adjudication(source, verdict)
            return unless source

            case verdict
            when :accepted then source.record_verified!
            when :rejected then source.record_refuted!
            end
          end

          def verdict_counts
            CLAIM_VERDICTS.to_h do |v|
              [v, @claims.values.count { |c| c.verdict == v }]
            end
          end
        end
      end
    end
  end
end
