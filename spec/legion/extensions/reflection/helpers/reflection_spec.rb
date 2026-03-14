# frozen_string_literal: true

RSpec.describe Legion::Extensions::Reflection::Helpers::ReflectionFactory do
  describe '.new_reflection' do
    it 'creates a reflection with required fields' do
      r = described_class.new_reflection(
        category:    :prediction_calibration,
        observation: 'Low accuracy detected'
      )
      expect(r[:reflection_id]).to be_a(String)
      expect(r[:category]).to eq(:prediction_calibration)
      expect(r[:observation]).to eq('Low accuracy detected')
      expect(r[:severity]).to eq(:notable)
      expect(r[:recommendation]).to eq(:no_action)
      expect(r[:acted_on]).to be false
    end

    it 'raises on invalid category' do
      expect { described_class.new_reflection(category: :invalid, observation: 'x') }
        .to raise_error(ArgumentError, /invalid category/)
    end

    it 'raises on invalid severity' do
      expect { described_class.new_reflection(category: :trust_drift, observation: 'x', severity: :invalid) }
        .to raise_error(ArgumentError, /invalid severity/)
    end
  end

  describe '.severity_weight' do
    it 'returns 1.0 for critical' do
      expect(described_class.severity_weight(:critical)).to eq(1.0)
    end

    it 'returns lower weights for lower severities' do
      expect(described_class.severity_weight(:trivial)).to be < described_class.severity_weight(:notable)
      expect(described_class.severity_weight(:notable)).to be < described_class.severity_weight(:significant)
    end
  end

  describe '.severity_for_drop' do
    it 'returns critical for large drops' do
      expect(described_class.severity_for_drop(0.5)).to eq(:critical)
    end

    it 'returns trivial for small drops' do
      expect(described_class.severity_for_drop(0.05)).to eq(:trivial)
    end
  end
end
