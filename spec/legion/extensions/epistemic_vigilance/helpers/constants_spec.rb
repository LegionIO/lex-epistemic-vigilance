# frozen_string_literal: true

RSpec.describe Legion::Extensions::EpistemicVigilance::Helpers::Constants do
  subject(:mod) { described_class }

  describe 'VIGILANCE_LEVELS' do
    it 'defines four levels in order' do
      expect(mod::VIGILANCE_LEVELS).to eq(%i[trusting cautious skeptical hostile])
    end

    it 'is frozen' do
      expect(mod::VIGILANCE_LEVELS).to be_frozen
    end
  end

  describe 'VIGILANCE_THRESHOLDS' do
    it 'defines trusting at 0.8' do
      expect(mod::VIGILANCE_THRESHOLDS[:trusting]).to eq(0.8)
    end

    it 'defines hostile at 0.0' do
      expect(mod::VIGILANCE_THRESHOLDS[:hostile]).to eq(0.0)
    end
  end

  describe 'CLAIM_VERDICTS' do
    it 'includes accepted and rejected' do
      expect(mod::CLAIM_VERDICTS).to include(:accepted, :rejected)
    end

    it 'is frozen' do
      expect(mod::CLAIM_VERDICTS).to be_frozen
    end
  end

  describe 'SOURCE_RELIABILITY_LABELS' do
    it 'maps 0.9 to highly_reliable' do
      label = mod::SOURCE_RELIABILITY_LABELS.find { |range, _| range.include?(0.9) }&.last
      expect(label).to eq(:highly_reliable)
    end

    it 'maps 0.1 to deceptive' do
      label = mod::SOURCE_RELIABILITY_LABELS.find { |range, _| range.include?(0.1) }&.last
      expect(label).to eq(:deceptive)
    end

    it 'maps 0.5 to uncertain' do
      label = mod::SOURCE_RELIABILITY_LABELS.find { |range, _| range.include?(0.5) }&.last
      expect(label).to eq(:uncertain)
    end
  end

  describe 'weights' do
    it 'weights sum to 1.0' do
      total = mod::CONSISTENCY_WEIGHT + mod::SOURCE_WEIGHT + mod::COHERENCE_WEIGHT
      expect(total).to be_within(0.001).of(1.0)
    end
  end
end
