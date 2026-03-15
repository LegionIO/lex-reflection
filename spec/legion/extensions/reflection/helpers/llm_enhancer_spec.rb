# frozen_string_literal: true

RSpec.describe Legion::Extensions::Reflection::Helpers::LlmEnhancer do
  describe '.available?' do
    context 'when Legion::LLM is not defined' do
      it 'returns a falsy value' do
        # Legion::LLM is not defined in the test environment
        expect(described_class.available?).to be_falsy
      end
    end

    context 'when Legion::LLM is defined but not started' do
      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: false))
      end

      it 'returns false' do
        expect(described_class.available?).to be false
      end
    end

    context 'when Legion::LLM is started' do
      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: true))
      end

      it 'returns true' do
        expect(described_class.available?).to be true
      end
    end

    context 'when an error is raised' do
      before do
        stub_const('Legion::LLM', double)
        allow(Legion::LLM).to receive(:respond_to?).and_raise(StandardError)
      end

      it 'returns false' do
        expect(described_class.available?).to be false
      end
    end
  end

  describe '.enhance_reflection' do
    let(:fake_response) do
      double(content: <<~TEXT)
        EMOTION: My arousal is elevated at 0.7 while stability holds at 0.8, suggesting urgency without destabilization.
        PREDICTION: Confidence at 65% with a declining trend and 3 pending predictions signals I am losing ground in forward modeling.
        MEMORY: Memory health appears nominal with no concerning decay patterns detected this cycle.
        TRUST: Trust scores remain stable with no significant drift observed.
        CURIOSITY: Curiosity intensity is moderate; resolution rates suggest effective exploration.
        IDENTITY: Identity entropy is within expected bounds; no drift detected.
      TEXT
    end
    let(:fake_chat) { double }
    let(:monitors_data) do
      [
        {
          category:       :emotional_stability,
          observation:    'original',
          severity:       :notable,
          metrics:        { stability: 0.8 },
          recommendation: :no_action
        },
        {
          category:       :prediction_calibration,
          observation:    'original',
          severity:       :notable,
          metrics:        { confidence: 0.65 },
          recommendation: :increase_curiosity
        }
      ]
    end
    let(:health_scores) do
      {
        prediction_calibration:  0.65,
        curiosity_effectiveness: 0.8,
        emotional_stability:     0.8,
        trust_drift:             1.0,
        memory_health:           0.95,
        cognitive_load:          0.9,
        mode_patterns:           1.0
      }
    end

    before do
      stub_const('Legion::LLM', double)
      allow(Legion::LLM).to receive(:chat).and_return(fake_chat)
      allow(fake_chat).to receive(:with_instructions)
      allow(fake_chat).to receive(:ask).and_return(fake_response)
    end

    it 'returns observations hash with at least some categories' do
      result = described_class.enhance_reflection(
        monitors_data: monitors_data,
        health_scores: health_scores
      )
      expect(result).to be_a(Hash)
      expect(result[:observations]).to be_a(Hash)
      expect(result[:observations]).not_to be_empty
    end

    it 'parses per-category observation text' do
      result = described_class.enhance_reflection(
        monitors_data: monitors_data,
        health_scores: health_scores
      )
      expect(result[:observations][:emotional_stability]).to include('arousal')
      expect(result[:observations][:prediction_calibration]).to include('Confidence')
    end

    context 'when LLM returns nil content' do
      before { allow(fake_chat).to receive(:ask).and_return(double(content: nil)) }

      it 'returns nil' do
        result = described_class.enhance_reflection(
          monitors_data: monitors_data,
          health_scores: health_scores
        )
        expect(result).to be_nil
      end
    end

    context 'when LLM raises an error' do
      before { allow(fake_chat).to receive(:ask).and_raise(StandardError, 'LLM timeout') }

      it 'returns nil and logs a warning' do
        expect(Legion::Logging).to receive(:warn).with(/enhance_reflection failed/)
        result = described_class.enhance_reflection(
          monitors_data: monitors_data,
          health_scores: health_scores
        )
        expect(result).to be_nil
      end
    end
  end

  describe '.reflect_on_dream' do
    let(:fake_response) do
      double(content: <<~TEXT)
        REFLECTION: The dream cycle surfaced 3 unresolved traces and resolved 1 contradiction. Memory consolidation is progressing normally with agenda items focused on identity coherence.
      TEXT
    end
    let(:fake_chat) { double }
    let(:dream_results) do
      {
        memory_audit:             { decayed: 5, pruned: 2, unresolved_count: 3 },
        contradiction_resolution: { detected: 2, resolved: 1 },
        agenda_formation:         { agenda_items: 4 }
      }
    end

    before do
      stub_const('Legion::LLM', double)
      allow(Legion::LLM).to receive(:chat).and_return(fake_chat)
      allow(fake_chat).to receive(:with_instructions)
      allow(fake_chat).to receive(:ask).and_return(fake_response)
    end

    it 'returns a reflection string' do
      result = described_class.reflect_on_dream(dream_results: dream_results)
      expect(result).to be_a(Hash)
      expect(result[:reflection]).to be_a(String)
      expect(result[:reflection]).not_to be_empty
    end

    it 'includes dream cycle content in the reflection' do
      result = described_class.reflect_on_dream(dream_results: dream_results)
      expect(result[:reflection]).to include('unresolved traces')
    end

    context 'when LLM returns nil content' do
      before { allow(fake_chat).to receive(:ask).and_return(double(content: nil)) }

      it 'returns nil' do
        result = described_class.reflect_on_dream(dream_results: dream_results)
        expect(result).to be_nil
      end
    end

    context 'when LLM raises an error' do
      before { allow(fake_chat).to receive(:ask).and_raise(StandardError, 'model error') }

      it 'returns nil and logs a warning' do
        expect(Legion::Logging).to receive(:warn).with(/reflect_on_dream failed/)
        result = described_class.reflect_on_dream(dream_results: dream_results)
        expect(result).to be_nil
      end
    end
  end
end
