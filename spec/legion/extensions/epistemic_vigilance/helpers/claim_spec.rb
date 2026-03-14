# frozen_string_literal: true

RSpec.describe Legion::Extensions::EpistemicVigilance::Helpers::Claim do
  subject(:claim) do
    described_class.new(content: 'the sky is blue', source_id: 'src-1', domain: :weather, confidence: 0.5)
  end

  describe '#initialize' do
    it 'generates a UUID id' do
      expect(claim.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'starts with :suspended verdict' do
      expect(claim.verdict).to eq(:suspended)
    end

    it 'starts with zero evidence' do
      expect(claim.evidence_for).to eq(0)
      expect(claim.evidence_against).to eq(0)
    end

    it 'clamps confidence to 0..1' do
      over = described_class.new(content: 'x', source_id: 's', domain: :d, confidence: 1.5)
      under = described_class.new(content: 'x', source_id: 's', domain: :d, confidence: -0.5)
      expect(over.confidence).to eq(1.0)
      expect(under.confidence).to eq(0.0)
    end
  end

  describe '#support!' do
    it 'increments evidence_for' do
      expect { claim.support! }.to change(claim, :evidence_for).by(1)
    end

    it 'increases confidence by 0.05' do
      before = claim.confidence
      claim.support!
      expect(claim.confidence).to be_within(0.001).of(before + 0.05)
    end

    it 'clamps confidence at 1.0' do
      strong = described_class.new(content: 'x', source_id: 's', domain: :d, confidence: 0.98)
      strong.support!
      expect(strong.confidence).to eq(1.0)
    end
  end

  describe '#challenge!' do
    it 'increments evidence_against' do
      expect { claim.challenge! }.to change(claim, :evidence_against).by(1)
    end

    it 'decreases confidence by 0.08' do
      before = claim.confidence
      claim.challenge!
      expect(claim.confidence).to be_within(0.001).of(before - 0.08)
    end

    it 'clamps confidence at 0.0' do
      weak = described_class.new(content: 'x', source_id: 's', domain: :d, confidence: 0.03)
      weak.challenge!
      expect(weak.confidence).to eq(0.0)
    end
  end

  describe '#credibility_ratio' do
    it 'returns 0.0 with no evidence' do
      expect(claim.credibility_ratio).to eq(0.0 / 1.0)
    end

    it 'is higher with more evidence_for' do
      3.times { claim.support! }
      claim.challenge!
      expect(claim.credibility_ratio).to be > 0.5
    end
  end

  describe '#contested?' do
    it 'is false with no challenges' do
      3.times { claim.support! }
      expect(claim.contested?).to be false
    end

    it 'is true when challenged and credibility_ratio < 0.6' do
      claim.support!
      3.times { claim.challenge! }
      expect(claim.contested?).to be true
    end
  end

  describe '#well_supported?' do
    it 'is false initially' do
      expect(claim.well_supported?).to be false
    end

    it 'is true with 3+ for and credibility > 0.7' do
      4.times { claim.support! }
      expect(claim.well_supported?).to be true
    end

    it 'is false when challenged enough to lower credibility_ratio' do
      3.times { claim.support! }
      5.times { claim.challenge! }
      expect(claim.well_supported?).to be false
    end
  end

  describe '#adjudicate!' do
    it 'sets the verdict' do
      claim.adjudicate!(verdict: :accepted)
      expect(claim.verdict).to eq(:accepted)
    end

    it 'can be set to rejected' do
      claim.adjudicate!(verdict: :rejected)
      expect(claim.verdict).to eq(:rejected)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = claim.to_h
      expect(h).to include(:id, :content, :source_id, :domain, :confidence, :verdict,
                           :evidence_for, :evidence_against, :credibility_ratio,
                           :contested, :well_supported, :created_at)
    end

    it 'reflects current state' do
      claim.support!
      h = claim.to_h
      expect(h[:evidence_for]).to eq(1)
      expect(h[:confidence]).to be > 0.5
    end
  end
end
