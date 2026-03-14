# frozen_string_literal: true

module Legion
  module Extensions
    module Reflection
      module Helpers
        class ReflectionStore
          attr_reader :total_generated

          def initialize
            @reflections = {}
            @total_generated = 0
            @category_scores = Hash.new(1.0)
          end

          def store(reflection)
            prune_oldest if @reflections.size >= Constants::MAX_REFLECTIONS
            @reflections[reflection[:reflection_id]] = reflection
            @total_generated += 1
            reflection
          end

          def get(reflection_id)
            @reflections[reflection_id]
          end

          def recent(limit: 10)
            @reflections.values
                        .sort_by { |r| r[:created_at] }
                        .last(limit)
                        .reverse
          end

          def by_category(category)
            @reflections.values.select { |r| r[:category] == category }
          end

          def by_severity(severity)
            @reflections.values.select { |r| r[:severity] == severity }
          end

          def mark_acted_on(reflection_id)
            reflection = @reflections[reflection_id]
            return nil unless reflection

            @reflections[reflection_id] = reflection.merge(acted_on: true)
          end

          def unacted
            @reflections.values.reject { |r| r[:acted_on] }
          end

          def count
            @reflections.size
          end

          def severity_counts
            counts = Hash.new(0)
            @reflections.each_value { |r| counts[r[:severity]] += 1 }
            counts
          end

          def category_counts
            counts = Hash.new(0)
            @reflections.each_value { |r| counts[r[:category]] += 1 }
            counts
          end

          def update_category_score(category, score)
            @category_scores[category] = score.clamp(0.0, 1.0)
          end

          def cognitive_health
            total_weight = Constants::HEALTH_WEIGHTS.values.sum
            weighted_sum = Constants::HEALTH_WEIGHTS.sum do |cat, weight|
              @category_scores[cat] * weight
            end
            (weighted_sum / total_weight).round(3)
          end

          def category_score(category)
            @category_scores[category]
          end

          private

          def prune_oldest
            oldest = @reflections.values.min_by { |r| r[:created_at] }
            @reflections.delete(oldest[:reflection_id]) if oldest
          end
        end
      end
    end
  end
end
