# lex-epistemic-vigilance

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Epistemic vigilance modeling for the LegionIO cognitive architecture. Implements Sperber and Mercier's epistemic vigilance framework — the cognitive mechanism for evaluating the credibility of information from other agents before integrating it. Assesses source reliability, detects manipulation signals, applies plausibility checks, and manages an accept/reject/quarantine decision for incoming claims. Protects the agent's belief system from corruption via unreliable or adversarial sources.

## Gem Info

- **Gem name**: `lex-epistemic-vigilance`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::EpistemicVigilance`
- **Location**: `extensions-agentic/lex-epistemic-vigilance/`

## File Structure

```
lib/legion/extensions/epistemic_vigilance/
  epistemic_vigilance.rb        # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # CREDIBILITY_FACTORS, MANIPULATION_SIGNALS, VERDICT_TYPES, thresholds
    source_model.rb             # SourceModel: per-source credibility tracking
    claim.rb                    # Claim value object with verdict
    vigilance_engine.rb         # Engine: source registry, claim evaluation, manipulation detection
  runners/
    epistemic_vigilance.rb      # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `ACCEPTANCE_THRESHOLD` | 0.6 | Minimum credibility score to accept a claim |
| `QUARANTINE_THRESHOLD` | 0.3 | Below this, claim is quarantined (not integrated) |
| `MANIPULATION_PENALTY` | 0.3 | Credibility deduction when manipulation signal detected |
| `ACCURACY_REINFORCEMENT` | 0.1 | Source credibility boost on verified accurate claim |
| `ACCURACY_PENALTY` | 0.15 | Source credibility penalty on verified false claim |
| `VIGILANCE_DECAY` | 0.01 | Alert level decays per cycle when no threats detected |
| `MAX_SOURCES` | 100 | Source model registry cap |
| `MAX_CLAIMS` | 500 | Rolling claim log cap |
| `VERDICT_TYPES` | `[:accepted, :rejected, :quarantined, :pending]` | Claim evaluation outcomes |
| `MANIPULATION_SIGNALS` | array | Signal types: `:urgency`, `:flattery`, `:authority_appeal`, `:emotional_pressure`, `:inconsistency` |
| `CREDIBILITY_LABELS` | range hash | `highly_credible / credible / uncertain / low_credibility / suspect` |
| `ALERT_LABELS` | range hash | `high_alert / elevated / normal / low` |

## Runners

All methods in `Legion::Extensions::EpistemicVigilance::Runners::EpistemicVigilance`.

| Method | Key Args | Returns |
|---|---|---|
| `evaluate_claim` | `source_id:, claim:, context: {}` | `{ success:, claim_id:, verdict:, credibility_score:, manipulation_detected: }` |
| `register_source` | `source_id:, initial_credibility: 0.5` | `{ success:, source_id:, credibility:, registered: }` |
| `update_source_accuracy` | `source_id:, claim_id:, accurate:` | `{ success:, source_id:, credibility_before:, credibility_after: }` |
| `source_credibility` | `source_id:` | `{ success:, source_id:, credibility:, credibility_label:, claim_count: }` |
| `quarantined_claims` | — | `{ success:, claims:, count: }` |
| `vigilance_status` | — | `{ success:, alert_level:, alert_label:, active_threats:, quarantine_count: }` |
| `most_credible_sources` | `limit: 5` | `{ success:, sources:, count: }` |
| `least_credible_sources` | `limit: 5` | `{ success:, sources:, count: }` |
| `update_epistemic_vigilance` | — | `{ success:, alert_decayed:, claims_pruned: }` |
| `epistemic_vigilance_stats` | — | Full stats hash |

## Helpers

### `SourceModel`
Per-source credibility tracker. Attributes: `id`, `credibility` (float 0–1), `claim_count`, `accurate_count`, `manipulation_count`, `created_at`, `last_contact_at`. Key methods: `reinforce!` (add `ACCURACY_REINFORCEMENT`), `penalize!` (subtract `ACCURACY_PENALTY`), `manipulation_detected!` (subtract `MANIPULATION_PENALTY`), `accuracy_rate`, `credibility_label`, `to_h`.

### `Claim`
Value object. Attributes: `id`, `source_id`, `content`, `context`, `verdict`, `credibility_at_evaluation`, `manipulation_signals` (array), `timestamp`. `to_h`.

### `VigilanceEngine`
Central store: `@sources` (hash by source_id), `@claims` (array, rolling), `@alert_level` (float 0–1). Key methods:
- `evaluate(source_id:, claim:, context:)`: retrieves or creates SourceModel, detects manipulation signals in context, adjusts effective credibility, assigns verdict based on thresholds
- `detect_manipulation(context:)`: scans context for `MANIPULATION_SIGNALS`, returns detected signals array, calls `source.manipulation_detected!` if any found, raises alert level
- `alert_level`: composite of recent manipulation detections and low-credibility source activity
- `decay_alert`: reduces `@alert_level` by `VIGILANCE_DECAY` per cycle

## Integration Points

- `evaluate_claim` called from lex-mesh message receipt before integrating information into agent state
- `quarantined_claims` reviewed by lex-governance's oversight layer
- `vigilance_status[:alert_level]` feeds lex-emotion as a threat/anxiety signal
- `source_credibility` informs lex-trust's agent reliability assessments
- `update_epistemic_vigilance` maps to lex-tick's periodic maintenance cycle

## Development Notes

- Unknown sources (not registered) are auto-created with `initial_credibility: 0.5` (neutral prior)
- Quarantined claims are retained in the log — they are not deleted, enabling later review
- Manipulation detection is pattern-based on context keys/values, not semantic analysis
- Alert level rises sharply on manipulation detection and decays slowly (asymmetric by design)
- `ACCEPTANCE_THRESHOLD` and `QUARANTINE_THRESHOLD` create a middle zone (0.3–0.6) where claims are `:pending`
