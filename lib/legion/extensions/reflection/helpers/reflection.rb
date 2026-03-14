# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Reflection
      module Helpers
        module ReflectionFactory
          module_function

          def new_reflection(category:, observation:, severity: :notable,
                             metrics: {}, recommendation: :no_action)
            raise ArgumentError, "invalid category: #{category}" unless Constants::CATEGORIES.include?(category)
            raise ArgumentError, "invalid severity: #{severity}" unless Constants::SEVERITIES.include?(severity)

            {
              reflection_id:  SecureRandom.uuid,
              category:       category,
              observation:    observation,
              severity:       severity,
              metrics:        metrics,
              recommendation: recommendation,
              created_at:     Time.now.utc,
              acted_on:       false
            }
          end

          def severity_weight(severity)
            case severity
            when :critical    then 1.0
            when :significant then 0.7
            when :notable     then 0.4
            when :trivial     then 0.1
            else 0.0
            end
          end

          def severity_for_drop(drop)
            if drop >= 0.4 then :critical
            elsif drop >= 0.25 then :significant
            elsif drop >= 0.1  then :notable
            else :trivial
            end
          end
        end
      end
    end
  end
end
