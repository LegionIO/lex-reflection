# frozen_string_literal: true

module Legion
  module Extensions
    module Reflection
      module Helpers
        module LlmEnhancer
          SYSTEM_PROMPT = <<~PROMPT
            You are the metacognitive reflection engine for an autonomous AI agent built on LegionIO.
            You analyze post-tick cognitive metrics and produce insightful observations.
            Be analytical and specific. Reference the actual numbers. Identify correlations between metrics.
            Write as internal reflection, not a report. Present tense, first person.
          PROMPT

          # Maps prompt label -> actual category symbol from Constants::CATEGORIES
          CATEGORY_LABEL_MAP = {
            'EMOTION'    => :emotional_stability,
            'PREDICTION' => :prediction_calibration,
            'MEMORY'     => :memory_health,
            'TRUST'      => :trust_drift,
            'CURIOSITY'  => :curiosity_effectiveness,
            'IDENTITY'   => :mode_patterns
          }.freeze

          REFLECTION_CATEGORIES = CATEGORY_LABEL_MAP.keys.freeze

          module_function

          def available?
            defined?(Legion::LLM) && Legion::LLM.respond_to?(:started?) && Legion::LLM.started?
          rescue StandardError
            false
          end

          def enhance_reflection(monitors_data:, health_scores:)
            prompt = build_enhance_reflection_prompt(monitors_data: monitors_data, health_scores: health_scores)
            response = llm_ask(prompt)
            parse_enhance_reflection_response(response)
          rescue StandardError => e
            Legion::Logging.warn "[reflection:llm] enhance_reflection failed: #{e.message}"
            nil
          end

          def reflect_on_dream(dream_results:)
            prompt = build_reflect_on_dream_prompt(dream_results: dream_results)
            response = llm_ask(prompt)
            parse_reflect_on_dream_response(response)
          rescue StandardError => e
            Legion::Logging.warn "[reflection:llm] reflect_on_dream failed: #{e.message}"
            nil
          end

          # --- Private helpers ---

          def llm_ask(prompt)
            chat = Legion::LLM.chat
            chat.with_instructions(SYSTEM_PROMPT)
            chat.ask(prompt)
          end
          private_class_method :llm_ask

          def build_enhance_reflection_prompt(monitors_data:, health_scores:)
            metrics_lines = format_monitors_data(monitors_data)
            health_lines  = health_scores.map { |cat, score| "#{cat}: #{score.round(3)}" }.join("\n")

            <<~PROMPT
              Analyze these post-tick cognitive metrics and generate insightful observations.

              METRICS:
              #{metrics_lines}

              HEALTH SCORES:
              #{health_lines}

              For each category, write 1-2 sentences of genuine analytical observation.
              Look for correlations between categories. Note concerning or interesting patterns.

              Format EXACTLY as (one line per category):
              EMOTION: <observation>
              PREDICTION: <observation>
              MEMORY: <observation>
              TRUST: <observation>
              CURIOSITY: <observation>
              IDENTITY: <observation>
            PROMPT
          end
          private_class_method :build_enhance_reflection_prompt

          def format_monitors_data(monitors_data)
            return '' unless monitors_data.is_a?(Array)

            monitors_data.filter_map do |entry|
              next unless entry.is_a?(Hash) && entry[:category]

              metrics = entry[:metrics]
              if metrics.is_a?(Hash) && metrics.any?
                metric_str = metrics.map { |k, v| "#{k}=#{v.is_a?(Float) ? v.round(3) : v}" }.join(', ')
                "#{entry[:category].to_s.upcase}: #{metric_str}"
              else
                entry[:category].to_s.upcase
              end
            end.join("\n")
          end
          private_class_method :format_monitors_data

          def parse_enhance_reflection_response(response)
            return nil unless response&.content

            observations = {}
            CATEGORY_LABEL_MAP.each do |label, category_sym|
              match = response.content.match(/^#{label}:\s*(.+)$/i)
              observations[category_sym] = match.captures.first.strip if match
            end

            observations.empty? ? nil : { observations: observations }
          end
          private_class_method :parse_enhance_reflection_response

          def build_reflect_on_dream_prompt(dream_results:)
            summary = format_dream_results(dream_results)

            <<~PROMPT
              Reflect on the completed dream cycle and its cognitive significance.

              DREAM CYCLE RESULTS:
              #{summary}

              Generate a first-person, present-tense reflection on what emerged from this dream cycle.
              Be specific about patterns, consolidations, and what needs attention.

              Format EXACTLY as:
              REFLECTION: <2-4 sentences of internal reflection>
            PROMPT
          end
          private_class_method :build_reflect_on_dream_prompt

          def format_dream_results(dream_results)
            return 'no results' unless dream_results.is_a?(Hash) && dream_results.any?

            dream_results.map do |phase, result|
              next unless result.is_a?(Hash)

              summary = result.except(:error).map { |k, v| "#{k}=#{v}" }.first(4).join(', ')
              "#{phase}: #{summary}"
            end.compact.join("\n")
          end
          private_class_method :format_dream_results

          def parse_reflect_on_dream_response(response)
            return nil unless response&.content

            match = response.content.match(/REFLECTION:\s*(.+)/im)
            return nil unless match

            { reflection: match.captures.first.strip }
          end
          private_class_method :parse_reflect_on_dream_response
        end
      end
    end
  end
end
