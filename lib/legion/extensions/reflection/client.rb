# frozen_string_literal: true

require 'legion/extensions/reflection/helpers/constants'
require 'legion/extensions/reflection/helpers/reflection'
require 'legion/extensions/reflection/helpers/reflection_store'
require 'legion/extensions/reflection/helpers/monitors'
require 'legion/extensions/reflection/runners/reflection'

module Legion
  module Extensions
    module Reflection
      class Client
        include Runners::Reflection

        attr_reader :reflection_store

        def initialize(store: nil, **)
          @reflection_store = store || Helpers::ReflectionStore.new
        end
      end
    end
  end
end
