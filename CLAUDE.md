# lex-reflection

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-reflection`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::Reflection`

## Purpose

Meta-cognitive monitoring and adaptation engine. Each tick, analyzes tick results across seven cognitive categories to detect notable patterns (low prediction accuracy, curiosity imbalance, emotional instability, trust drift, memory decay ratio, cognitive load, mode oscillation). Generates structured reflection entries with severity labels and actionable recommendations. Maintains per-category health scores that combine into a weighted `cognitive_health` score.

## Gem Info

- **Homepage**: https://github.com/LegionIO/lex-reflection
- **License**: MIT
- **Ruby**: >= 3.4

## File Structure

```
lib/legion/extensions/reflection/
  version.rb
  client.rb
  helpers/
    constants.rb         # CATEGORIES, SEVERITIES, RECOMMENDATIONS, thresholds, HEALTH_WEIGHTS
    reflection.rb        # Reflection helper/struct
    reflection_store.rb  # ReflectionStore — stores reflections, computes health
    monitors.rb          # Monitors module — detection logic per category
  runners/
    reflection.rb        # Runner module
spec/
  helpers/monitors_spec.rb
  helpers/reflection_spec.rb
  helpers/reflection_store_spec.rb
  runners/reflection_spec.rb
  client_spec.rb
```

## Key Constants

From `Helpers::Constants`:
- `CATEGORIES = %i[prediction_calibration curiosity_effectiveness emotional_stability trust_drift memory_health cognitive_load mode_patterns]`
- `SEVERITIES = %i[trivial notable significant critical]`
- `RECOMMENDATIONS = %i[increase_curiosity decrease_curiosity stabilize_emotion rebuild_trust consolidate_memory reduce_load celebrate_success investigate no_action]`
- `MAX_REFLECTIONS = 100`
- `METRIC_WINDOW_SIZE = 20` (rolling history size)
- `HEALTH_WEIGHTS`: prediction_calibration: 0.25, curiosity_effectiveness: 0.15, emotional_stability: 0.15, trust_drift: 0.15, memory_health: 0.15, cognitive_load: 0.15
- Detection thresholds: `PREDICTION_ACCURACY_LOW = 0.4`, `PREDICTION_ACCURACY_DROP = 0.2`, `EMOTION_INSTABILITY_THRESHOLD = 0.3`, `TRUST_DROP_THRESHOLD = 0.15`, `MEMORY_DECAY_RATIO_HIGH = 0.8`, `BUDGET_OVER_THRESHOLD = 0.9`

## Runners

| Method | Key Parameters | Returns |
|---|---|---|
| `reflect` | `tick_results: {}` | `{ reflections_generated:, cognitive_health:, new_reflections:, total_reflections: }` |
| `cognitive_health` | — | `{ health:, category_scores:, unacted_count:, critical_count:, significant_count: }` |
| `recent_reflections` | `limit: 10` | `{ reflections: }` formatted array |
| `reflections_by_category` | `category:` | `{ category:, reflections: }` |
| `adapt` | `reflection_id:` | marks reflection as acted on — `{ adapted:, reflection_id:, recommendation: }` |
| `reflection_stats` | — | total_generated, current_count, cognitive_health, severity_counts, category_counts, unacted |

## Helpers

### `Helpers::Monitors`
`module_function` module with detection logic. `run_all(tick_results, history)` runs all monitors and returns array of reflection hashes. Per-category monitors extract relevant keys from tick_results and compare to thresholds. Each monitor returns nil (no issue) or a reflection hash with `category`, `observation`, `severity`, `recommendation`.

### `Helpers::ReflectionStore`
Rolling store capped at `MAX_REFLECTIONS`. Maintains per-category scores (EMA-updated). `store(reflection)` assigns UUID, adds `acted_on: false`. `get(id)` finds by UUID. `mark_acted_on(id)`. `cognitive_health` = weighted sum of category scores using `HEALTH_WEIGHTS`. `by_severity(sev)`, `by_category(cat)` filter. `unacted` = reflections with `acted_on: false`. `severity_counts`, `category_counts` tallies.

### `Helpers::Monitors` detection signals
- `prediction_calibration`: reads `tick_results[:prediction_engine][:confidence]`
- `curiosity_effectiveness`: reads `tick_results[:working_memory_integration][:curiosity_intensity]`
- `emotional_stability`: reads `tick_results[:emotional_evaluation][:stability]`
- `memory_health`: reads `tick_results[:memory_consolidation][:pruned]` / `[:total]`
- `cognitive_load`: reads `tick_results[:elapsed]` / `[:budget]`

## Integration Points

- `reflect` is the canonical `post_tick_reflection` handler wired by `lex-cortex`
- `cognitive_health` feeds `lex-self-talk` for inner deliberation triggering
- Critical reflections (`:critical` severity) can trigger `lex-governance` proposals
- `reflections_by_category(:trust_drift)` feeds `lex-trust` recalibration
- `adapt` marks reflections acted on — tracks which recommendations were followed
- `reflection_store.cognitive_health` below threshold triggers escalated monitoring

## Development Notes

- `reflect` maintains a rolling `@metric_history` array (max `METRIC_WINDOW_SIZE`) on the runner instance
- `cognitive_health` uses `HEALTH_WEIGHTS` (6 categories, weights sum to 1.0); `mode_patterns` not in weights
- Category score updates are independent — each reads a different tick_result key
- Reflection IDs are UUIDs assigned at store time (not at monitor detection time)
- `update_category_score` for cognitive_load uses `1.0 - (elapsed / budget)` clamped to 0
- All state is in-memory; reset on process restart
