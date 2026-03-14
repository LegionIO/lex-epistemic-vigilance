# frozen_string_literal: true

RSpec.describe Legion::Extensions::EpistemicVigilance::Helpers::VigilanceEngine do
  subject(:engine) { described_class.new }

  let(:source_result) { engine.register_source(name: 'ResearchBot', domain: :science) }
  let(:source_id) { source_result[:id] }

  describe '#register_source' do
    it 'returns a hash with id, name, domain' do
      expect(source_result).to include(:id, :name, :domain)
    end

    it 'sets name and domain' do
      expect(source_result[:name]).to eq('ResearchBot')
      expect(source_result[:domain]).to eq(:science)
    end

    it 'starts with default reliability' do
      expect(source_result[:reliability]).to eq(0.5)
    end
  end

  describe '#submit_claim' do
    it 'returns error when source not found' do
      result = engine.submit_claim(content: 'x', source_id: 'bad', domain: :d)
      expect(result[:error]).to eq(:source_not_found)
    end

    it 'returns claim and assessment' do
      result = engine.submit_claim(content: 'water boils at 100C', source_id: source_id, domain: :science)
      expect(result).to include(:claim, :assessment)
    end

    it 'includes recommended_verdict in assessment' do
      result = engine.submit_claim(content: 'water boils at 100C', source_id: source_id, domain: :science)
      expect(result[:assessment]).to include(:recommended_verdict)
    end

    it 'increments source claims_made' do
      engine.submit_claim(content: 'water boils at 100C', source_id: source_id, domain: :science)
      report = engine.source_reliability(source_id: source_id)
      expect(report[:reliability]).to be >= 0.5
    end
  end

  describe '#assess_claim' do
    it 'returns error for missing claim' do
      result = engine.assess_claim(claim_id: 'nonexistent')
      expect(result[:error]).to eq(:claim_not_found)
    end

    it 'returns all score components' do
      claim_result = engine.submit_claim(content: 'test', source_id: source_id, domain: :science)
      claim_id = claim_result[:claim][:id]
      assessment = engine.assess_claim(claim_id: claim_id)
      expect(assessment).to include(:source_score, :consistency_score, :coherence_score,
                                    :total_score, :recommended_verdict)
    end

    it 'source_score reflects source weight' do
      claim_result = engine.submit_claim(content: 'test', source_id: source_id, domain: :science)
      claim_id = claim_result[:claim][:id]
      assessment = engine.assess_claim(claim_id: claim_id)
      expected = 0.5 * Legion::Extensions::EpistemicVigilance::Helpers::Constants::SOURCE_WEIGHT
      expect(assessment[:source_score]).to be_within(0.001).of(expected)
    end
  end

  describe '#support_claim' do
    let(:claim_id) do
      engine.submit_claim(content: 'test', source_id: source_id, domain: :science)[:claim][:id]
    end

    it 'returns error for unknown claim' do
      expect(engine.support_claim(claim_id: 'bad')[:error]).to eq(:claim_not_found)
    end

    it 'increments evidence_for' do
      result = engine.support_claim(claim_id: claim_id)
      expect(result[:evidence_for]).to eq(1)
    end

    it 'increases confidence' do
      engine.submit_claim(content: 'test', source_id: source_id, domain: :science)
      result = engine.support_claim(claim_id: claim_id)
      expect(result[:confidence]).to be > 0.5
    end

    it 'boosts source reliability' do
      before = engine.source_reliability(source_id: source_id)[:reliability]
      engine.support_claim(claim_id: claim_id)
      after = engine.source_reliability(source_id: source_id)[:reliability]
      expect(after).to be > before
    end
  end

  describe '#challenge_claim' do
    let(:claim_id) do
      engine.submit_claim(content: 'test', source_id: source_id, domain: :science)[:claim][:id]
    end

    it 'returns error for unknown claim' do
      expect(engine.challenge_claim(claim_id: 'bad')[:error]).to eq(:claim_not_found)
    end

    it 'increments evidence_against' do
      result = engine.challenge_claim(claim_id: claim_id)
      expect(result[:evidence_against]).to eq(1)
    end

    it 'decreases confidence' do
      result = engine.challenge_claim(claim_id: claim_id)
      expect(result[:confidence]).to be < 0.5
    end

    it 'penalizes source reliability' do
      before = engine.source_reliability(source_id: source_id)[:reliability]
      engine.challenge_claim(claim_id: claim_id)
      after = engine.source_reliability(source_id: source_id)[:reliability]
      expect(after).to be < before
    end
  end

  describe '#adjudicate_claim' do
    let(:claim_id) do
      engine.submit_claim(content: 'test', source_id: source_id, domain: :science)[:claim][:id]
    end

    it 'returns error for unknown claim' do
      expect(engine.adjudicate_claim(claim_id: 'bad', verdict: :accepted)[:error]).to eq(:claim_not_found)
    end

    it 'sets the verdict' do
      result = engine.adjudicate_claim(claim_id: claim_id, verdict: :accepted)
      expect(result[:verdict]).to eq(:accepted)
    end

    it 'boosts source reliability on accepted' do
      before = engine.source_reliability(source_id: source_id)[:reliability]
      engine.adjudicate_claim(claim_id: claim_id, verdict: :accepted)
      after = engine.source_reliability(source_id: source_id)[:reliability]
      expect(after).to be > before
    end

    it 'penalizes source reliability on rejected' do
      before = engine.source_reliability(source_id: source_id)[:reliability]
      engine.adjudicate_claim(claim_id: claim_id, verdict: :rejected)
      after = engine.source_reliability(source_id: source_id)[:reliability]
      expect(after).to be < before
    end
  end

  describe '#source_reliability' do
    it 'returns error for unknown source' do
      expect(engine.source_reliability(source_id: 'bad')[:error]).to eq(:source_not_found)
    end

    it 'returns reliability and label' do
      result = engine.source_reliability(source_id: source_id)
      expect(result).to include(:reliability, :label)
    end
  end

  describe '#contested_claims' do
    it 'returns empty when no contested claims' do
      expect(engine.contested_claims).to eq([])
    end

    it 'returns claims that are contested' do
      claim_id = engine.submit_claim(content: 'test', source_id: source_id, domain: :science)[:claim][:id]
      engine.support_claim(claim_id: claim_id)
      3.times { engine.challenge_claim(claim_id: claim_id) }
      contested = engine.contested_claims
      expect(contested.size).to eq(1)
    end
  end

  describe '#claims_by_source' do
    it 'returns claims for the given source' do
      engine.submit_claim(content: 'a', source_id: source_id, domain: :science)
      engine.submit_claim(content: 'b', source_id: source_id, domain: :science)
      result = engine.claims_by_source(source_id: source_id)
      expect(result.size).to eq(2)
    end

    it 'returns empty for unknown source' do
      expect(engine.claims_by_source(source_id: 'nobody')).to eq([])
    end
  end

  describe '#claims_by_domain' do
    it 'returns claims for the given domain' do
      engine.submit_claim(content: 'x', source_id: source_id, domain: :science)
      engine.submit_claim(content: 'y', source_id: source_id, domain: :science)
      result = engine.claims_by_domain(domain: :science)
      expect(result.size).to eq(2)
    end

    it 'filters by domain' do
      engine.submit_claim(content: 'x', source_id: source_id, domain: :science)
      result = engine.claims_by_domain(domain: :other)
      expect(result).to eq([])
    end
  end

  describe '#domain_vigilance_level' do
    it 'returns :skeptical for empty domain' do
      expect(engine.domain_vigilance_level(domain: :unknown)).to eq(:skeptical)
    end

    it 'returns a valid vigilance level' do
      engine.submit_claim(content: 'test', source_id: source_id, domain: :science)
      level = engine.domain_vigilance_level(domain: :science)
      expect(Legion::Extensions::EpistemicVigilance::Helpers::Constants::VIGILANCE_LEVELS).to include(level)
    end

    it 'returns :hostile for low-confidence domain' do
      claim_id = engine.submit_claim(content: 'test', source_id: source_id,
                                     domain: :science, initial_confidence: 0.05)[:claim][:id]
      5.times { engine.challenge_claim(claim_id: claim_id) }
      level = engine.domain_vigilance_level(domain: :science)
      expect(%i[skeptical hostile]).to include(level)
    end
  end

  describe '#decay_all' do
    it 'returns count of decayed claims' do
      engine.submit_claim(content: 'test', source_id: source_id, domain: :science)
      result = engine.decay_all
      expect(result[:decayed]).to eq(1)
    end

    it 'reduces claim confidence' do
      engine.submit_claim(content: 'test', source_id: source_id, domain: :science)[:claim][:id]
      before = engine.claims_by_domain(domain: :science).first[:confidence]
      engine.decay_all
      after = engine.claims_by_domain(domain: :science).first[:confidence]
      expect(after).to be < before
    end
  end

  describe '#prune_rejected' do
    it 'removes rejected claims below 0.1 confidence' do
      claim_id = engine.submit_claim(content: 'garbage', source_id: source_id,
                                     domain: :science, initial_confidence: 0.05)[:claim][:id]
      engine.adjudicate_claim(claim_id: claim_id, verdict: :rejected)
      result = engine.prune_rejected
      expect(result[:pruned]).to eq(1)
    end

    it 'keeps rejected claims above 0.1 confidence' do
      claim_id = engine.submit_claim(content: 'maybe', source_id: source_id,
                                     domain: :science, initial_confidence: 0.5)[:claim][:id]
      engine.adjudicate_claim(claim_id: claim_id, verdict: :rejected)
      engine.prune_rejected
      expect(engine.claims_by_domain(domain: :science).size).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      result = engine.to_h
      expect(result).to include(:sources_count, :claims_count, :contested, :by_verdict)
    end

    it 'reflects current state' do
      engine.submit_claim(content: 'test', source_id: source_id, domain: :science)
      expect(engine.to_h[:claims_count]).to eq(1)
      expect(engine.to_h[:sources_count]).to eq(1)
    end
  end
end
