# frozen_string_literal: true

module Workspace::Member::Remove
  def self.call(uuid:)
    Workspace::Member.find_by(uuid:)&.destroy!
  end
end
