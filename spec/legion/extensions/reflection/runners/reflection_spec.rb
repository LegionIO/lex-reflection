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

  describe '#reflect with LLM enhancement' do
    let(:fake_chat) { double }
    let(:llm_observation) { 'My prediction confidence is critically low at 10%, strongly correlated with declining memory health.' }
    let(:fake_response) do
      double(content: <<~TEXT)
        EMOTION: Emotional state appears stable this tick.
        PREDICTION: #{llm_observation}
        MEMORY: Memory health is nominal.
        TRUST: Trust scores unchanged.
        CURIOSITY: Curiosity levels normal.
        IDENTITY: Identity entropy within bounds.
      TEXT
    end

    before do
      stub_const('Legion::LLM', double(respond_to?: true, started?: true))
      allow(Legion::LLM).to receive(:chat).and_return(fake_chat)
      allow(fake_chat).to receive(:with_instructions)
      allow(fake_chat).to receive(:ask).and_return(fake_response)
    end

    it 'replaces mechanical observation text with LLM-generated text' do
      result = client.reflect(tick_results: { prediction_engine: { confidence: 0.1 } })
      prediction_reflection = result[:new_reflections].find { |r| r[:category] == :prediction_calibration }
      expect(prediction_reflection).not_to be_nil
      expect(prediction_reflection[:observation]).to include('critically low')
    end

    it 'does not change recommendation symbols when using LLM' do
      result = client.reflect(tick_results: { prediction_engine: { confidence: 0.1 } })
      prediction_reflection = result[:new_reflections].find { |r| r[:category] == :prediction_calibration }
      expect(prediction_reflection).not_to be_nil
      expect(prediction_reflection[:recommendation]).to eq(:increase_curiosity)
    end

    it 'falls back to mechanical observations when LLM returns nil' do
      allow(fake_chat).to receive(:ask).and_return(double(content: nil))

      result = client.reflect(tick_results: {
                                prediction_engine:    { confidence: 0.2 },
                                emotional_evaluation: { stability: 0.1 }
                              })
      expect(result[:reflections_generated]).to be >= 1
      # Mechanical observations still present (LLM returned nil)
      result[:new_reflections].each do |r|
        expect(r[:observation]).to be_a(String)
        expect(r[:observation]).not_to be_empty
      end
    end
  end

  describe '#reflect_on_dream' do
    context 'without LLM' do
      it 'uses mechanical fallback for empty dream results' do
        result = client.reflect_on_dream(dream_results: {})
        expect(result[:reflection]).to eq('Dream cycle completed.')
        expect(result[:source]).to eq(:mechanical)
      end

      it 'builds mechanical reflection from dream phase data' do
        result = client.reflect_on_dream(dream_results: {
                                           memory_audit:             { decayed: 3, unresolved_count: 2 },
                                           contradiction_resolution: { detected: 1, resolved: 1 },
                                           agenda_formation:         { agenda_items: 3 }
                                         })
        expect(result[:reflection]).to include('Memory audit')
        expect(result[:source]).to eq(:mechanical)
      end
    end

    context 'with LLM available' do
      let(:fake_chat) { double }
      let(:fake_response) do
        double(content: <<~TEXT)
          REFLECTION: The dream cycle consolidated 3 traces and resolved a contradiction in the identity domain. I notice a strengthening of procedural memory pathways.
        TEXT
      end

      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: true))
        allow(Legion::LLM).to receive(:chat).and_return(fake_chat)
        allow(fake_chat).to receive(:with_instructions)
        allow(fake_chat).to receive(:ask).and_return(fake_response)
      end

      it 'uses LLM-generated reflection when available' do
        result = client.reflect_on_dream(dream_results: {
                                           memory_audit:             { decayed: 3, unresolved_count: 2 },
                                           contradiction_resolution: { detected: 1, resolved: 1 }
                                         })
        expect(result[:reflection]).to include('consolidated 3 traces')
        expect(result[:source]).to eq(:llm)
      end

      it 'falls back to mechanical when LLM returns nil' do
        allow(fake_chat).to receive(:ask).and_return(double(content: nil))

        result = client.reflect_on_dream(dream_results: {
                                           memory_audit: { decayed: 1, unresolved_count: 0 }
                                         })
        expect(result[:source]).to eq(:mechanical)
        expect(result[:reflection]).to be_a(String)
        expect(result[:reflection]).not_to be_empty
      end
    end
  end
end
