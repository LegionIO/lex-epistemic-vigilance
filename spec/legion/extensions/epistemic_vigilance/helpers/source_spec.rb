# frozen_string_literal: true

RSpec.describe Legion::Extensions::EpistemicVigilance::Helpers::Source do
  subject(:source) { described_class.new(name: 'NewsBot', domain: :news) }

  let(:boost)   { Legion::Extensions::EpistemicVigilance::Helpers::Constants::RELIABILITY_BOOST }
  let(:penalty) { Legion::Extensions::EpistemicVigilance::Helpers::Constants::RELIABILITY_PENALTY }
  let(:default) { Legion::Extensions::EpistemicVigilance::Helpers::Constants::DEFAULT_SOURCE_RELIABILITY }

  describe '#initialize' do
    it 'generates a UUID id' do
      expect(source.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'starts with default reliability 0.5' do
      expect(source.reliability).to eq(default)
    end

    it 'starts with zero claim counts' do
      expect(source.claims_made).to eq(0)
      expect(source.claims_verified).to eq(0)
      expect(source.claims_refuted).to eq(0)
    end
  end

  describe '#record_verified!' do
    it 'increments claims_verified' do
      expect { source.record_verified! }.to change(source, :claims_verified).by(1)
    end

    it 'boosts reliability' do
      before = source.reliability
      source.record_verified!
      expect(source.reliability).to be_within(0.001).of(before + boost)
    end

    it 'clamps reliability at 1.0' do
      high = described_class.new(name: 'top', domain: :d)
      high.reliability = 0.99
      high.record_verified!
      expect(high.reliability).to eq(1.0)
    end
  end

  describe '#record_refuted!' do
    it 'increments claims_refuted' do
      expect { source.record_refuted! }.to change(source, :claims_refuted).by(1)
    end

    it 'penalizes reliability' do
      before = source.reliability
      source.record_refuted!
      expect(source.reliability).to be_within(0.001).of(before - penalty)
    end

    it 'clamps reliability at 0.0' do
      low = described_class.new(name: 'spammer', domain: :d)
      low.reliability = 0.05
      low.record_refuted!
      expect(low.reliability).to eq(0.0)
    end

    it 'penalizes more than boost (asymmetric)' do
      expect(penalty).to be > boost
    end
  end

  describe '#reliability_label' do
    it 'returns :highly_reliable at 0.9' do
      source.reliability = 0.9
      expect(source.reliability_label).to eq(:highly_reliable)
    end

    it 'returns :deceptive at 0.1' do
      source.reliability = 0.1
      expect(source.reliability_label).to eq(:deceptive)
    end

    it 'returns :uncertain at 0.5' do
      expect(source.reliability_label).to eq(:uncertain)
    end

    it 'returns :reliable at 0.7' do
      source.reliability = 0.7
      expect(source.reliability_label).to eq(:reliable)
    end

    it 'returns :unreliable at 0.3' do
      source.reliability = 0.3
      expect(source.reliability_label).to eq(:unreliable)
    end
  end

  describe '#track_record' do
    it 'returns 0.0 / 1.0 with no activity' do
      expect(source.track_record).to be_within(0.001).of(0.0)
    end

    it 'improves with verifications' do
      3.times { source.record_verified! }
      expect(source.track_record).to be > 0.5
    end

    it 'decreases with refutations' do
      3.times { source.record_refuted! }
      expect(source.track_record).to be_within(0.001).of(0.0)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = source.to_h
      expect(h).to include(:id, :name, :domain, :reliability, :reliability_label,
                           :claims_made, :claims_verified, :claims_refuted, :track_record)
    end
  end
end
