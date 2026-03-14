# frozen_string_literal: true

RSpec.describe Legion::Extensions::Reflection::Helpers::ReflectionStore do
  subject(:store) { described_class.new }

  let(:reflection) do
    Legion::Extensions::Reflection::Helpers::ReflectionFactory.new_reflection(
      category:       :prediction_calibration,
      observation:    'Low accuracy',
      severity:       :significant,
      recommendation: :increase_curiosity
    )
  end

  describe '#store and #get' do
    it 'stores and retrieves a reflection' do
      store.store(reflection)
      expect(store.get(reflection[:reflection_id])).to eq(reflection)
    end

    it 'increments total_generated' do
      store.store(reflection)
      expect(store.total_generated).to eq(1)
    end
  end

  describe '#recent' do
    it 'returns reflections in reverse chronological order' do
      r1 = Legion::Extensions::Reflection::Helpers::ReflectionFactory.new_reflection(
        category: :trust_drift, observation: 'first'
      )
      store.store(r1)
      r2 = Legion::Extensions::Reflection::Helpers::ReflectionFactory.new_reflection(
        category: :memory_health, observation: 'second'
      )
      store.store(r2)

      recent = store.recent(limit: 2)
      expect(recent.first[:observation]).to eq('second')
    end
  end

  describe '#by_category' do
    it 'filters by category' do
      store.store(reflection)
      other = Legion::Extensions::Reflection::Helpers::ReflectionFactory.new_reflection(
        category: :trust_drift, observation: 'other'
      )
      store.store(other)

      results = store.by_category(:prediction_calibration)
      expect(results.size).to eq(1)
      expect(results.first[:category]).to eq(:prediction_calibration)
    end
  end

  describe '#mark_acted_on' do
    it 'marks a reflection as acted on' do
      store.store(reflection)
      store.mark_acted_on(reflection[:reflection_id])
      expect(store.get(reflection[:reflection_id])[:acted_on]).to be true
    end

    it 'returns nil for unknown id' do
      expect(store.mark_acted_on('nonexistent')).to be_nil
    end
  end

  describe '#cognitive_health' do
    it 'returns 1.0 when all scores are at default' do
      expect(store.cognitive_health).to eq(1.0)
    end

    it 'decreases when category scores drop' do
      store.update_category_score(:prediction_calibration, 0.3)
      expect(store.cognitive_health).to be < 1.0
    end
  end

  describe '#severity_counts' do
    it 'counts reflections by severity' do
      store.store(reflection)
      critical = Legion::Extensions::Reflection::Helpers::ReflectionFactory.new_reflection(
        category: :cognitive_load, observation: 'overload', severity: :critical
      )
      store.store(critical)

      counts = store.severity_counts
      expect(counts[:significant]).to eq(1)
      expect(counts[:critical]).to eq(1)
    end
  end
end
