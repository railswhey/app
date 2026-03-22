# frozen_string_literal: true

module Orchestrator
  module Revertible
    private

    def undo(condition)
      yield rescue ActiveRecord::ActiveRecordError if condition
    end
  end

  def self.new(...) = Struct.new(...).tap { it.include(Revertible) }
end
