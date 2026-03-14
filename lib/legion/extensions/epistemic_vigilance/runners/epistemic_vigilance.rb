# frozen_string_literal: true

module Legion
  module Extensions
    module EpistemicVigilance
      module Runners
        module EpistemicVigilance
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def register_epistemic_source(name:, domain:, **)
            result = engine.register_source(name: name, domain: domain)
            Legion::Logging.info "[epistemic_vigilance] registered source name=#{name} domain=#{domain} id=#{result[:id]}"
            result
          end

          def submit_epistemic_claim(content:, source_id:, domain:, initial_confidence: 0.5, **)
            result = engine.submit_claim(content: content, source_id: source_id, domain: domain,
                                         initial_confidence: initial_confidence)
            Legion::Logging.debug "[epistemic_vigilance] claim submitted domain=#{domain} verdict=#{result.dig(:assessment, :recommended_verdict)}"
            result
          end

          def assess_epistemic_claim(claim_id:, **)
            result = engine.assess_claim(claim_id: claim_id)
            Legion::Logging.debug "[epistemic_vigilance] assess claim_id=#{claim_id} total=#{result[:total_score]&.round(3)}"
            result
          end

          def support_epistemic_claim(claim_id:, **)
            result = engine.support_claim(claim_id: claim_id)
            Legion::Logging.debug "[epistemic_vigilance] support claim_id=#{claim_id} confidence=#{result[:confidence]&.round(3)}"
            result
          end

          def challenge_epistemic_claim(claim_id:, **)
            result = engine.challenge_claim(claim_id: claim_id)
            Legion::Logging.debug "[epistemic_vigilance] challenge claim_id=#{claim_id} confidence=#{result[:confidence]&.round(3)}"
            result
          end

          def adjudicate_epistemic_claim(claim_id:, verdict:, **)
            result = engine.adjudicate_claim(claim_id: claim_id, verdict: verdict)
            Legion::Logging.info "[epistemic_vigilance] adjudicate claim_id=#{claim_id} verdict=#{verdict}"
            result
          end

          def source_reliability_report(source_id:, **)
            result = engine.source_reliability(source_id: source_id)
            Legion::Logging.debug "[epistemic_vigilance] source reliability source_id=#{source_id} label=#{result[:label]}"
            result
          end

          def contested_claims_report(**)
            claims = engine.contested_claims
            Legion::Logging.debug "[epistemic_vigilance] contested claims count=#{claims.size}"
            { contested: claims, count: claims.size }
          end

          def domain_vigilance_report(domain:, **)
            level = engine.domain_vigilance_level(domain: domain)
            claims = engine.claims_by_domain(domain: domain)
            Legion::Logging.debug "[epistemic_vigilance] domain=#{domain} vigilance_level=#{level} claims=#{claims.size}"
            { domain: domain, vigilance_level: level, claims: claims, count: claims.size }
          end

          def update_epistemic_vigilance(**)
            decay_result = engine.decay_all
            prune_result = engine.prune_rejected
            Legion::Logging.debug "[epistemic_vigilance] decay+prune decayed=#{decay_result[:decayed]} pruned=#{prune_result[:pruned]}"
            { decay: decay_result, prune: prune_result }
          end

          def epistemic_vigilance_stats(**)
            engine.to_h
          end

          private

          def engine
            @engine ||= Helpers::VigilanceEngine.new
          end
        end
      end
    end
  end
end
