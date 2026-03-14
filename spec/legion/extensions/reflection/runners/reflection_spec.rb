# frozen_string_literal: true

RSpec.describe Legion::Extensions::Reflection::Runners::Reflection do
  let(:client) { Legion::Extensions::Reflection::Client.new }

  describe '#reflect' do
    it 'returns results with no tick data' do
      result = client.reflect(tick_results: {})
      expect(result[:reflections_generated]).to eq(0)
      expect(result[:cognitive_health]).to eq(1.0)
    end

    it 'generates reflections from problematic tick results' do
      result = client.reflect(tick_results: {
                                prediction_engine:    { confidence: 0.2 },
                                emotional_evaluation: { stability: 0.1 },
                                memory_consolidation: { pruned: 90, total: 100 }
                              })
      expect(result[:reflections_generated]).to be >= 2
      expect(result[:cognitive_health]).to be < 1.0
    end

    it 'accumulates metric history over multiple calls' do
      5.times { client.reflect(tick_results: { prediction_engine: { confidence: 0.9 } }) }
      5.times { client.reflect(tick_results: { prediction_engine: { confidence: 0.4 } }) }

      # Should detect trend
      result = client.reflect(tick_results: { prediction_engine: { confidence: 0.3 } })
      predictions = result[:new_reflections].select { |r| r[:category] == :prediction_calibration }
      expect(predictions).not_to be_empty
    end
  end

  describe '#cognitive_health' do
    it 'returns full health with no data' do
      result = client.cognitive_health
      expect(result[:health]).to eq(1.0)
    end

    it 'degrades with bad tick results' do
      client.reflect(tick_results: {
                       prediction_engine:    { confidence: 0.2 },
                       emotional_evaluation: { stability: 0.1 }
                     })
      result = client.cognitive_health
      expect(result[:health]).to be < 1.0
      expect(result[:category_scores][:prediction_calibration]).to eq(0.2)
    end
  end

  describe '#recent_reflections' do
    it 'returns recent reflections' do
      client.reflect(tick_results: { prediction_engine: { confidence: 0.1 } })
      result = client.recent_reflections(limit: 5)
      expect(result[:reflections]).not_to be_empty
    end
  end

  describe '#reflections_by_category' do
    it 'filters by category' do
      client.reflect(tick_results: {
                       prediction_engine:    { confidence: 0.1 },
                       emotional_evaluation: { stability: 0.1 }
                     })
      result = client.reflections_by_category(category: :emotional_stability)
      result[:reflections].each do |r|
        expect(r[:category]).to eq(:emotional_stability)
      end
    end
  end

  describe '#adapt' do
    it 'marks a reflection as acted upon' do
      client.reflect(tick_results: { prediction_engine: { confidence: 0.1 } })
      reflections = client.recent_reflections[:reflections]
      id = reflections.first[:reflection_id]

      result = client.adapt(reflection_id: id)
      expect(result[:adapted]).to be true
    end

    it 'returns error for unknown id' do
      result = client.adapt(reflection_id: 'nonexistent')
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#reflection_stats' do
    it 'returns comprehensive stats' do
      client.reflect(tick_results: { prediction_engine: { confidence: 0.1 } })
      stats = client.reflection_stats
      expect(stats[:total_generated]).to be >= 1
      expect(stats[:cognitive_health]).to be_a(Float)
      expect(stats[:severity_counts]).to be_a(Hash)
    end
  end
end
