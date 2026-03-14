# frozen_string_literal: true

RSpec.describe Legion::Extensions::Reflection::Helpers::Monitors do
  describe '.monitor_predictions' do
    it 'generates reflection for low confidence' do
      results = described_class.monitor_predictions(
        { prediction_engine: { confidence: 0.2 } },
        []
      )
      expect(results.size).to be >= 1
      expect(results.first[:category]).to eq(:prediction_calibration)
      expect(results.first[:recommendation]).to eq(:increase_curiosity)
    end

    it 'returns empty for good confidence' do
      results = described_class.monitor_predictions(
        { prediction_engine: { confidence: 0.9 } },
        []
      )
      expect(results).to be_empty
    end

    it 'detects accuracy trend drop' do
      history = Array.new(5) { { prediction_engine: { confidence: 0.9 } } } +
                Array.new(5) { { prediction_engine: { confidence: 0.5 } } }

      results = described_class.monitor_predictions(
        { prediction_engine: { confidence: 0.5 } },
        history
      )
      trend = results.find { |r| r[:metrics][:trend_drop] }
      expect(trend).not_to be_nil
    end
  end

  describe '.monitor_curiosity' do
    it 'generates reflection for low resolution rate' do
      results = described_class.monitor_curiosity(
        working_memory_integration: { resolution_rate: 0.1 }
      )
      expect(results.size).to eq(1)
      expect(results.first[:recommendation]).to eq(:decrease_curiosity)
    end

    it 'celebrates high resolution rate' do
      results = described_class.monitor_curiosity(
        working_memory_integration: { resolution_rate: 0.9 }
      )
      expect(results.size).to eq(1)
      expect(results.first[:recommendation]).to eq(:celebrate_success)
    end
  end

  describe '.monitor_emotions' do
    it 'generates reflection for instability' do
      results = described_class.monitor_emotions(
        emotional_evaluation: { stability: 0.1 }
      )
      expect(results.size).to eq(1)
      expect(results.first[:category]).to eq(:emotional_stability)
      expect(results.first[:severity]).to eq(:significant)
    end

    it 'detects emotional flatness' do
      results = described_class.monitor_emotions(
        emotional_evaluation: { stability: 0.99 }
      )
      expect(results.size).to eq(1)
      expect(results.first[:observation]).to include('flat')
    end
  end

  describe '.monitor_memory' do
    it 'generates reflection for high decay ratio' do
      results = described_class.monitor_memory(
        memory_consolidation: { pruned: 90, total: 100 }
      )
      expect(results.size).to eq(1)
      expect(results.first[:recommendation]).to eq(:consolidate_memory)
    end

    it 'returns empty for healthy memory' do
      results = described_class.monitor_memory(
        memory_consolidation: { pruned: 5, total: 100 }
      )
      expect(results).to be_empty
    end
  end

  describe '.monitor_cognitive_load' do
    it 'generates reflection when near budget' do
      results = described_class.monitor_cognitive_load(
        elapsed: 4.8, budget: 5.0
      )
      expect(results.size).to eq(1)
      expect(results.first[:category]).to eq(:cognitive_load)
    end

    it 'returns empty when within budget' do
      results = described_class.monitor_cognitive_load(
        elapsed: 1.0, budget: 5.0
      )
      expect(results).to be_empty
    end
  end

  describe '.run_all' do
    it 'aggregates results from all monitors' do
      tick_results = {
        prediction_engine:    { confidence: 0.2 },
        emotional_evaluation: { stability: 0.1 },
        memory_consolidation: { pruned: 90, total: 100 },
        elapsed:              4.8,
        budget:               5.0
      }
      results = described_class.run_all(tick_results, [])
      expect(results.size).to be >= 3
    end
  end
end
