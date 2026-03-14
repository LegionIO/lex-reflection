# frozen_string_literal: true

module Legion
  module Extensions
    module Reflection
      module Helpers
        module Constants
          CATEGORIES = %i[
            prediction_calibration
            curiosity_effectiveness
            emotional_stability
            trust_drift
            memory_health
            cognitive_load
            mode_patterns
          ].freeze

          SEVERITIES = %i[trivial notable significant critical].freeze

          RECOMMENDATIONS = %i[
            increase_curiosity
            decrease_curiosity
            stabilize_emotion
            rebuild_trust
            consolidate_memory
            reduce_load
            celebrate_success
            investigate
            no_action
          ].freeze

          # Thresholds for monitor triggers
          PREDICTION_ACCURACY_LOW       = 0.4
          PREDICTION_ACCURACY_DROP      = 0.2
          CURIOSITY_RESOLUTION_LOW      = 0.2
          CURIOSITY_RESOLUTION_HIGH     = 0.8
          EMOTION_INSTABILITY_THRESHOLD = 0.3
          EMOTION_FLATNESS_THRESHOLD    = 0.05
          TRUST_DROP_THRESHOLD          = 0.15
          MEMORY_DECAY_RATIO_HIGH       = 0.8
          BUDGET_OVER_THRESHOLD         = 0.9
          MODE_OSCILLATION_THRESHOLD    = 5

          # Rolling window for metrics
          METRIC_WINDOW_SIZE = 20

          # Health score weights
          HEALTH_WEIGHTS = {
            prediction_calibration:  0.25,
            curiosity_effectiveness: 0.15,
            emotional_stability:     0.15,
            trust_drift:             0.15,
            memory_health:           0.15,
            cognitive_load:          0.15
          }.freeze

          MAX_REFLECTIONS = 100
        end
      end
    end
  end
end
