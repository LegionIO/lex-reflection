# frozen_string_literal: true

module Legion
  module Extensions
    module Reflection
      module Runners
        module Reflection
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def reflect(tick_results: {}, **)
            @metric_history ||= []
            @metric_history << tick_results
            @metric_history = @metric_history.last(Helpers::Constants::METRIC_WINDOW_SIZE)

            new_reflections = Helpers::Monitors.run_all(tick_results, @metric_history)
            new_reflections.each { |r| reflection_store.store(r) }

            update_category_scores(tick_results)

            Legion::Logging.debug "[reflection] generated #{new_reflections.size} reflections, health=#{reflection_store.cognitive_health}"

            {
              reflections_generated: new_reflections.size,
              cognitive_health:      reflection_store.cognitive_health,
              new_reflections:       new_reflections.map { |r| format_reflection(r) },
              total_reflections:     reflection_store.count
            }
          end

          def cognitive_health(**)
            health = reflection_store.cognitive_health
            Legion::Logging.debug "[reflection] cognitive health: #{health}"
            {
              health:            health,
              category_scores:   Helpers::Constants::CATEGORIES.to_h { |c| [c, reflection_store.category_score(c)] },
              unacted_count:     reflection_store.unacted.size,
              critical_count:    reflection_store.by_severity(:critical).size,
              significant_count: reflection_store.by_severity(:significant).size
            }
          end

          def recent_reflections(limit: 10, **)
            reflections = reflection_store.recent(limit: limit)
            { reflections: reflections.map { |r| format_reflection(r) } }
          end

          def reflections_by_category(category:, **)
            cat = category.to_sym
            reflections = reflection_store.by_category(cat)
            { category: cat, reflections: reflections.map { |r| format_reflection(r) } }
          end

          def adapt(reflection_id:, **)
            reflection = reflection_store.get(reflection_id)
            return { error: :not_found } unless reflection
            return { error: :already_acted } if reflection[:acted_on]

            reflection_store.mark_acted_on(reflection_id)
            Legion::Logging.info "[reflection] adapted: #{reflection[:observation]}"
            { adapted: true, reflection_id: reflection_id, recommendation: reflection[:recommendation] }
          end

          def reflection_stats(**)
            {
              total_generated:  reflection_store.total_generated,
              current_count:    reflection_store.count,
              cognitive_health: reflection_store.cognitive_health,
              severity_counts:  reflection_store.severity_counts,
              category_counts:  reflection_store.category_counts,
              unacted:          reflection_store.unacted.size
            }
          end

          private

          def reflection_store
            @reflection_store ||= Helpers::ReflectionStore.new
          end

          def format_reflection(reflection)
            {
              reflection_id:  reflection[:reflection_id],
              category:       reflection[:category],
              observation:    reflection[:observation],
              severity:       reflection[:severity],
              recommendation: reflection[:recommendation],
              acted_on:       reflection[:acted_on],
              created_at:     reflection[:created_at]
            }
          end

          def update_category_scores(tick_results)
            update_prediction_score(tick_results)
            update_curiosity_score(tick_results)
            update_emotion_score(tick_results)
            update_memory_score(tick_results)
            update_load_score(tick_results)
          end

          def update_prediction_score(tick_results)
            prediction = tick_results[:prediction_engine]
            return unless prediction.is_a?(Hash) && prediction[:confidence].is_a?(Numeric)

            reflection_store.update_category_score(:prediction_calibration, prediction[:confidence])
          end

          def update_curiosity_score(tick_results)
            curiosity = tick_results[:working_memory_integration]
            return unless curiosity.is_a?(Hash) && curiosity[:curiosity_intensity].is_a?(Numeric)

            score = 1.0 - ([curiosity[:curiosity_intensity], 1.0].min * 0.3)
            reflection_store.update_category_score(:curiosity_effectiveness, score)
          end

          def update_emotion_score(tick_results)
            emotion = tick_results[:emotional_evaluation]
            stability = emotion.is_a?(Hash) ? (emotion[:stability] || emotion.dig(:momentum, :stability)) : nil
            return unless stability.is_a?(Numeric)

            reflection_store.update_category_score(:emotional_stability, stability)
          end

          def update_memory_score(tick_results)
            memory = tick_results[:memory_consolidation]
            return unless memory.is_a?(Hash) && memory[:total].is_a?(Numeric) && memory[:total].positive?

            ratio = (memory[:pruned] || 0).to_f / memory[:total]
            reflection_store.update_category_score(:memory_health, 1.0 - ratio)
          end

          def update_load_score(tick_results)
            elapsed = tick_results[:elapsed]
            budget = tick_results[:budget]
            return unless elapsed.is_a?(Numeric) && budget.is_a?(Numeric) && budget.positive?

            utilization = elapsed / budget
            reflection_store.update_category_score(:cognitive_load, [1.0 - utilization, 0.0].max)
          end
        end
      end
    end
  end
end
