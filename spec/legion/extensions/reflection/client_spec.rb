# frozen_string_literal: true

RSpec.describe Legion::Extensions::Reflection::Client do
  subject(:client) { described_class.new }

  it 'initializes with a default reflection store' do
    expect(client.reflection_store).to be_a(Legion::Extensions::Reflection::Helpers::ReflectionStore)
  end

  it 'accepts an injected store' do
    custom = Legion::Extensions::Reflection::Helpers::ReflectionStore.new
    client = described_class.new(store: custom)
    expect(client.reflection_store).to be(custom)
  end

  it 'includes the Reflection runner' do
    expect(client).to respond_to(:reflect)
    expect(client).to respond_to(:cognitive_health)
    expect(client).to respond_to(:recent_reflections)
    expect(client).to respond_to(:reflections_by_category)
    expect(client).to respond_to(:adapt)
    expect(client).to respond_to(:reflection_stats)
  end
end
