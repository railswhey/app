# frozen_string_literal: true

class Workspace::Member::Add
  def initialize(workspace_uuid:)
    @workspace_uuid = workspace_uuid
  end

  def call(uuid:, email:, username:)
    workspace = ::Workspace.find_by!(uuid: @workspace_uuid)

    ::Workspace::Member.find_or_create_by!(uuid:) do
      it.email     = email
      it.username  = username
      it.workspace = workspace
      it.role      = :collaborator
    end
  end
end
