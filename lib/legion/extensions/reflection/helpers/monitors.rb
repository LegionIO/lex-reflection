# frozen_string_literal: true

module Legion
  module Extensions
    module Reflection
      module Helpers
        module Monitors
          module_function

          def run_all(tick_results, metric_history)
            reflections = []
            reflections.concat(monitor_predictions(tick_results, metric_history))
            reflections.concat(monitor_curiosity(tick_results))
            reflections.concat(monitor_emotions(tick_results))
            reflections.concat(monitor_trust(tick_results, metric_history))
            reflections.concat(monitor_memory(tick_results))
            reflections.concat(monitor_cognitive_load(tick_results))
            reflections
          end

          def monitor_predictions(tick_results, history)
            prediction = tick_results[:prediction_engine]
            return [] unless prediction.is_a?(Hash)

            reflections = []
            confidence = prediction[:confidence]

            if confidence.is_a?(Numeric) && confidence < Constants::PREDICTION_ACCURACY_LOW
              reflections << ReflectionFactory.new_reflection(
                category:       :prediction_calibration,
                observation:    "Prediction confidence is low at #{(confidence * 100).round}%",
                severity:       ReflectionFactory.severity_for_drop(1.0 - confidence),
                metrics:        { confidence: confidence },
                recommendation: :increase_curiosity
              )
            end

            reflections.concat(detect_accuracy_trend(history))
            reflections
          end

          def monitor_curiosity(tick_results)
            curiosity = tick_results[:working_memory_integration]
            return [] unless curiosity.is_a?(Hash)

            reflections = []

            resolution_rate = curiosity[:resolution_rate] if curiosity.key?(:resolution_rate)
            if resolution_rate.is_a?(Numeric)
              if resolution_rate < Constants::CURIOSITY_RESOLUTION_LOW
                reflections << ReflectionFactory.new_reflection(
                  category:       :curiosity_effectiveness,
                  observation:    "Curiosity resolution rate is low at #{(resolution_rate * 100).round}%",
                  severity:       :notable,
                  metrics:        { resolution_rate: resolution_rate },
                  recommendation: :decrease_curiosity
                )
              elsif resolution_rate > Constants::CURIOSITY_RESOLUTION_HIGH
                reflections << ReflectionFactory.new_reflection(
                  category:       :curiosity_effectiveness,
                  observation:    "Curiosity resolution rate is excellent at #{(resolution_rate * 100).round}%",
                  severity:       :trivial,
                  metrics:        { resolution_rate: resolution_rate },
                  recommendation: :celebrate_success
                )
              end
            end

            reflections
          end

          def monitor_emotions(tick_results)
            emotion = tick_results[:emotional_evaluation]
            return [] unless emotion.is_a?(Hash)

            reflections = []
            stability = emotion[:stability] || emotion.dig(:momentum, :stability)

            if stability.is_a?(Numeric)
              if stability < Constants::EMOTION_INSTABILITY_THRESHOLD
                reflections << ReflectionFactory.new_reflection(
                  category:       :emotional_stability,
                  observation:    "Emotional state is unstable (stability: #{stability.round(2)})",
                  severity:       :significant,
                  metrics:        { stability: stability },
                  recommendation: :stabilize_emotion
                )
              elsif stability > (1.0 - Constants::EMOTION_FLATNESS_THRESHOLD)
                reflections << ReflectionFactory.new_reflection(
                  category:       :emotional_stability,
                  observation:    'Emotional state is unusually flat — possible disengagement',
                  severity:       :notable,
                  metrics:        { stability: stability },
                  recommendation: :investigate
                )
              end
            end

            reflections
          end

          def monitor_trust(tick_results, history)
            trust = tick_results[:action_selection]
            return [] unless trust.is_a?(Hash) && trust[:trust_score].is_a?(Numeric)

            trust_scores = history.filter_map { |h| h.dig(:action_selection, :trust_score) }
            return [] if trust_scores.size < 3

            recent_avg = trust_scores.last(5).sum / trust_scores.last(5).size.to_f
            older_avg = trust_scores.first(5).sum / trust_scores.first(5).size.to_f
            drop = older_avg - recent_avg

            return [] unless drop > Constants::TRUST_DROP_THRESHOLD

            [ReflectionFactory.new_reflection(
              category:       :trust_drift,
              observation:    "Trust scores have dropped by #{(drop * 100).round}% recently",
              severity:       ReflectionFactory.severity_for_drop(drop),
              metrics:        { drop: drop, recent_avg: recent_avg, older_avg: older_avg },
              recommendation: :rebuild_trust
            )]
          end

          def monitor_memory(tick_results)
            memory = tick_results[:memory_consolidation]
            return [] unless memory.is_a?(Hash)

            pruned = memory[:pruned] || 0
            total = memory[:total] || 1
            ratio = pruned.to_f / [total, 1].max

            return [] unless ratio > Constants::MEMORY_DECAY_RATIO_HIGH

            [ReflectionFactory.new_reflection(
              category:       :memory_health,
              observation:    "High memory decay ratio: #{(ratio * 100).round}% of traces pruned",
              severity:       :significant,
              metrics:        { pruned: pruned, total: total, ratio: ratio },
              recommendation: :consolidate_memory
            )]
          end

          def monitor_cognitive_load(tick_results)
            elapsed = tick_results[:elapsed]
            budget = tick_results[:budget]
            return [] unless elapsed.is_a?(Numeric) && budget.is_a?(Numeric) && budget.positive?

            utilization = elapsed / budget
            return [] unless utilization > Constants::BUDGET_OVER_THRESHOLD

            [ReflectionFactory.new_reflection(
              category:       :cognitive_load,
              observation:    "Tick budget utilization at #{(utilization * 100).round}%",
              severity:       utilization > 1.0 ? :significant : :notable,
              metrics:        { utilization: utilization, elapsed: elapsed, budget: budget },
              recommendation: :reduce_load
            )]
          end

          def detect_accuracy_trend(history)
            accuracies = history.filter_map { |h| h.dig(:prediction_engine, :confidence) }
            return [] if accuracies.size < 5

            recent = accuracies.last(5).sum / 5.0
            older = accuracies.first(5).sum / 5.0
            drop = older - recent

            return [] unless drop > Constants::PREDICTION_ACCURACY_DROP

            [ReflectionFactory.new_reflection(
              category:       :prediction_calibration,
              observation:    "Prediction accuracy trending down: #{(older * 100).round}% -> #{(recent * 100).round}%",
              severity:       ReflectionFactory.severity_for_drop(drop),
              metrics:        { trend_drop: drop, recent_avg: recent, older_avg: older },
              recommendation: :increase_curiosity
            )]
          end
        end
      end
    end
  end
end
