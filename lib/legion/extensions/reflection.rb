# frozen_string_literal: true

require 'legion/extensions/reflection/version'
require 'legion/extensions/reflection/helpers/constants'
require 'legion/extensions/reflection/helpers/reflection'
require 'legion/extensions/reflection/helpers/reflection_store'
require 'legion/extensions/reflection/helpers/monitors'
require 'legion/extensions/reflection/runners/reflection'
require 'legion/extensions/reflection/client'

module Legion
  module Extensions
    module Reflection
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
