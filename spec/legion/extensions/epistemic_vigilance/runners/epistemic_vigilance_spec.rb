# frozen_string_literal: true

require 'legion/extensions/epistemic_vigilance/client'

RSpec.describe Legion::Extensions::EpistemicVigilance::Runners::EpistemicVigilance do
  let(:client) { Legion::Extensions::EpistemicVigilance::Client.new }

  let(:source_id) do
    client.register_epistemic_source(name: 'TestSource', domain: :testing)[:id]
  end

  let(:claim_id) do
    client.submit_epistemic_claim(content: 'test claim', source_id: source_id, domain: :testing)[:claim][:id]
  end

  describe '#register_epistemic_source' do
    it 'returns a hash with id and name' do
      result = client.register_epistemic_source(name: 'ScienceBot', domain: :science)
      expect(result).to include(:id, :name, :domain)
      expect(result[:name]).to eq('ScienceBot')
    end
  end

  describe '#submit_epistemic_claim' do
    it 'returns claim and assessment' do
      result = client.submit_epistemic_claim(content: 'sky is blue', source_id: source_id, domain: :testing)
      expect(result).to include(:claim, :assessment)
    end

    it 'returns error for unknown source' do
      result = client.submit_epistemic_claim(content: 'x', source_id: 'bad', domain: :testing)
      expect(result[:error]).to eq(:source_not_found)
    end
  end

  describe '#assess_epistemic_claim' do
    it 'returns assessment with all score fields' do
      cid = claim_id
      result = client.assess_epistemic_claim(claim_id: cid)
      expect(result).to include(:source_score, :consistency_score, :coherence_score,
                                :total_score, :recommended_verdict)
    end

    it 'returns error for unknown claim' do
      result = client.assess_epistemic_claim(claim_id: 'bad')
      expect(result[:error]).to eq(:claim_not_found)
    end
  end

  describe '#support_epistemic_claim' do
    it 'increments evidence_for' do
      cid = claim_id
      result = client.support_epistemic_claim(claim_id: cid)
      expect(result[:evidence_for]).to eq(1)
    end

    it 'increases confidence' do
      cid = claim_id
      result = client.support_epistemic_claim(claim_id: cid)
      expect(result[:confidence]).to be > 0.5
    end
  end

  describe '#challenge_epistemic_claim' do
    it 'increments evidence_against' do
      cid = claim_id
      result = client.challenge_epistemic_claim(claim_id: cid)
      expect(result[:evidence_against]).to eq(1)
    end

    it 'decreases confidence' do
      cid = claim_id
      result = client.challenge_epistemic_claim(claim_id: cid)
      expect(result[:confidence]).to be < 0.5
    end
  end

  describe '#adjudicate_epistemic_claim' do
    it 'sets the verdict to accepted' do
      cid = claim_id
      result = client.adjudicate_epistemic_claim(claim_id: cid, verdict: :accepted)
      expect(result[:verdict]).to eq(:accepted)
    end

    it 'sets the verdict to rejected' do
      cid = claim_id
      result = client.adjudicate_epistemic_claim(claim_id: cid, verdict: :rejected)
      expect(result[:verdict]).to eq(:rejected)
    end
  end

  describe '#source_reliability_report' do
    it 'returns reliability and label' do
      sid = source_id
      result = client.source_reliability_report(source_id: sid)
      expect(result).to include(:reliability, :label)
    end

    it 'returns error for unknown source' do
      result = client.source_reliability_report(source_id: 'bad')
      expect(result[:error]).to eq(:source_not_found)
    end
  end

  describe '#contested_claims_report' do
    it 'returns contested claims list and count' do
      result = client.contested_claims_report
      expect(result).to include(:contested, :count)
    end

    it 'count matches contested array size' do
      result = client.contested_claims_report
      expect(result[:count]).to eq(result[:contested].size)
    end
  end

  describe '#domain_vigilance_report' do
    it 'returns domain, vigilance_level, claims, count' do
      result = client.domain_vigilance_report(domain: :testing)
      expect(result).to include(:domain, :vigilance_level, :claims, :count)
    end

    it 'includes submitted claims in domain' do
      claim_id # force creation
      result = client.domain_vigilance_report(domain: :testing)
      expect(result[:count]).to be >= 1
    end
  end

  describe '#update_epistemic_vigilance' do
    it 'returns decay and prune results' do
      result = client.update_epistemic_vigilance
      expect(result).to include(:decay, :prune)
    end

    it 'decays existing claims' do
      claim_id # create a claim
      result = client.update_epistemic_vigilance
      expect(result[:decay][:decayed]).to be >= 1
    end
  end

  describe '#epistemic_vigilance_stats' do
    it 'returns stats hash' do
      result = client.epistemic_vigilance_stats
      expect(result).to include(:sources_count, :claims_count, :contested, :by_verdict)
    end

    it 'reflects registered sources and submitted claims' do
      sid = source_id
      client.submit_epistemic_claim(content: 'test', source_id: sid, domain: :testing)
      stats = client.epistemic_vigilance_stats
      expect(stats[:sources_count]).to be >= 1
      expect(stats[:claims_count]).to be >= 1
    end
  end
end
