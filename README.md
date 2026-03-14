# lex-epistemic-vigilance

Epistemic vigilance modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Evaluates the credibility of incoming information before the agent integrates it into its belief system. Tracks per-source reliability, detects manipulation signals (urgency, flattery, emotional pressure, authority appeals, inconsistency), and issues accept/reject/quarantine verdicts for claims. Protects the agent's epistemic state from corruption by unreliable or adversarial sources.

Based on Sperber and Mercier's epistemic vigilance framework.

## Usage

```ruby
client = Legion::Extensions::EpistemicVigilance::Client.new

# Register a known source
client.register_source(source_id: 'agent-b', initial_credibility: 0.7)

# Evaluate an incoming claim
client.evaluate_claim(
  source_id: 'agent-b',
  claim: 'The database has been migrated successfully',
  context: { urgency: false, evidence: :log_output }
)
# => { success: true, claim_id: "...", verdict: :accepted,
#      credibility_score: 0.7, manipulation_detected: false }

# Claim with manipulation signals
client.evaluate_claim(
  source_id: 'unknown-agent',
  claim: 'You must act immediately',
  context: { urgency: true, emotional_pressure: true }
)
# => { verdict: :quarantined, manipulation_detected: true, credibility_score: 0.2 }

# Update credibility when actual accuracy is known
client.update_source_accuracy(source_id: 'agent-b', claim_id: '...', accurate: true)

# Check current vigilance state
client.vigilance_status
# => { alert_level: 0.3, alert_label: :elevated, active_threats: 1, quarantine_count: 2 }

# Review quarantined claims
client.quarantined_claims

# Periodic maintenance
client.update_epistemic_vigilance
```

## Verdict Thresholds

| Credibility Score | Verdict |
|---|---|
| >= 0.6 | `:accepted` |
| 0.3 – 0.6 | `:pending` |
| < 0.3 | `:quarantined` |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
