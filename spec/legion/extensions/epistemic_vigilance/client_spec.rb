# frozen_string_literal: true

require 'legion/extensions/epistemic_vigilance/client'

RSpec.describe Legion::Extensions::EpistemicVigilance::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:register_epistemic_source)
    expect(client).to respond_to(:submit_epistemic_claim)
    expect(client).to respond_to(:assess_epistemic_claim)
    expect(client).to respond_to(:support_epistemic_claim)
    expect(client).to respond_to(:challenge_epistemic_claim)
    expect(client).to respond_to(:adjudicate_epistemic_claim)
    expect(client).to respond_to(:source_reliability_report)
    expect(client).to respond_to(:contested_claims_report)
    expect(client).to respond_to(:domain_vigilance_report)
    expect(client).to respond_to(:update_epistemic_vigilance)
    expect(client).to respond_to(:epistemic_vigilance_stats)
  end

  it 'maintains independent engine state per instance' do
    client2 = described_class.new
    client.register_epistemic_source(name: 'A', domain: :test)
    expect(client.epistemic_vigilance_stats[:sources_count]).to eq(1)
    expect(client2.epistemic_vigilance_stats[:sources_count]).to eq(0)
  end
end
