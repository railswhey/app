# frozen_string_literal: true

module Workspace::Setup
  def self.call(uuid:, email:, username:)
    Workspace.transaction do
      workspace = Workspace.create!(uuid:)

      Workspace::Member.create!(uuid:, username:, email:, workspace:, role: :owner)

      workspace.lists.inbox.create!

      workspace
    end
  end
end
