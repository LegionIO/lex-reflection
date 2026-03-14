# lex-reflection

Metacognitive self-monitoring for the LegionIO brain-modeled cognitive architecture.

## What It Does

Models the prefrontal cortex's metacognitive function — the ability to think about thinking. Monitors cognitive performance across all agentic extensions, detects patterns and degradation, and generates structured reflections with adaptation recommendations.

## Core Concept: The Reflection

A reflection is a metacognitive observation about the agent's own cognitive performance.

```ruby
client = Legion::Extensions::Reflection::Client.new

# Feed tick results to generate reflections
result = client.reflect(tick_results: {
  prediction_engine: { confidence: 0.3 },
  emotional_evaluation: { stability: 0.2 },
  memory_consolidation: { pruned: 80, total: 100 }
})
# => { reflections_generated: 3, cognitive_health: 0.65, ... }

# Check cognitive health
health = client.cognitive_health
# => { health: 0.65, category_scores: { prediction_calibration: 0.3, ... } }
```

## Monitors

| Monitor | What It Watches | Triggers On |
|---------|----------------|-------------|
| Prediction | Accuracy trends | Low confidence, accuracy drops |
| Curiosity | Resolution rates | Too many unresolved wonders |
| Emotion | Momentum stability | Instability or flatness |
| Trust | Score trends | Sudden trust drops |
| Memory | Decay/reinforcement | High prune ratio |
| Cognitive Load | Budget utilization | Near or over budget |

## Severity Levels

`:trivial` < `:notable` < `:significant` < `:critical`

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
