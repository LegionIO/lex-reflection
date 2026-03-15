# lex-reflection

Meta-cognitive monitoring and adaptation engine for the LegionIO cognitive architecture. Generates structured self-assessments from tick data.

## What It Does

Each tick, analyzes cognitive performance across seven categories: prediction calibration, curiosity effectiveness, emotional stability, trust drift, memory health, cognitive load, and mode patterns. Detects notable patterns and generates reflection entries with severity labels and actionable recommendations. Maintains per-category health scores that combine into a weighted `cognitive_health` composite. Reflections can be marked as acted on to track which adaptations were followed.

## Usage

```ruby
client = Legion::Extensions::Reflection::Client.new

# Reflect on each tick's results
result = client.reflect(
  tick_results: {
    prediction_engine:          { confidence: 0.35 },
    working_memory_integration: { curiosity_intensity: 0.9 },
    emotional_evaluation:       { stability: 0.4, valence: -0.2 },
    memory_consolidation:       { pruned: 8, total: 10 },
    elapsed:                    4.8,
    budget:                     5.0
  }
)
# => { reflections_generated: 2, cognitive_health: 0.62,
#      new_reflections: [
#        { category: :prediction_calibration, severity: :significant,
#          observation: 'Prediction accuracy is below threshold',
#          recommendation: :investigate, acted_on: false }
#      ], total_reflections: 2 }

# Check cognitive health
client.cognitive_health
# => { health: 0.62, category_scores: { prediction_calibration: 0.35, ... },
#      unacted_count: 2, critical_count: 0, significant_count: 1 }

# Mark a reflection as acted on
client.adapt(reflection_id: reflection_id)

# Query reflections
client.recent_reflections(limit: 5)
client.reflections_by_category(category: :emotional_stability)
client.reflection_stats
```

## Monitored Categories

| Category | Signal |
|----------|--------|
| `prediction_calibration` | `tick_results[:prediction_engine][:confidence]` |
| `curiosity_effectiveness` | `tick_results[:working_memory_integration][:curiosity_intensity]` |
| `emotional_stability` | `tick_results[:emotional_evaluation][:stability]` |
| `memory_health` | pruned/total ratio from `memory_consolidation` |
| `cognitive_load` | elapsed/budget ratio |
| `trust_drift` | trust composite delta |
| `mode_patterns` | mode oscillation frequency |

## Severity Levels

`:trivial` < `:notable` < `:significant` < `:critical`

## LLM Enhancement

When `legion-llm` is loaded and started, `Helpers::LlmEnhancer` enriches reflection output with analytically generated prose.

**Methods**:

`LlmEnhancer.enhance_reflection(monitors_data:, health_scores:)` — takes the raw monitors data array and per-category health score hash produced by `Helpers::Monitors`, and returns `{ observations: { category_sym => "text", ... } }`. The runner replaces the `observation` string on each reflection entry with the LLM-generated text. All category, severity, and recommendation symbols are left untouched — only the human-readable observation string changes.

`LlmEnhancer.reflect_on_dream(dream_results:)` — takes the phase result hash from a completed dream cycle and returns `{ reflection: "..." }` containing a 2-4 sentence first-person, present-tense reflection on what emerged. Used by the `reflect_on_dream` runner method, which is called from `lex-dream`'s `dream_reflection` phase (phase 7). Returns `source: :llm` or `source: :mechanical` in the runner result.

**Availability gate**: `LlmEnhancer.available?` checks `Legion::LLM.started?`. Returns `false` if `legion-llm` is not loaded, not configured, or raises any error.

**Fallback**: When LLM is unavailable or either method returns `nil`, `reflect` uses the template observation strings from `Helpers::Monitors`, and `reflect_on_dream` uses `build_mechanical_dream_reflection` (assembles a sentence from memory audit, contradiction, and agenda counts).

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
