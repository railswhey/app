# frozen_string_literal: true

module API
  class Engine < ::Rails::Engine
    isolate_namespace API
  end
end
