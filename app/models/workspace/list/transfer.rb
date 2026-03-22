# frozen_string_literal: true

class Workspace::List::Transfer < Abstract::Workspace
  belongs_to :list, foreign_key: :workspace_list_id, class_name: "Workspace::List"
  belongs_to :initiated_by,   class_name: "Member"
  belongs_to :to_workspace,   class_name: "Workspace"
  belongs_to :from_workspace, class_name: "Workspace"

  has_secure_token :token

  enum :status, { pending: 0, accepted: 1, rejected: 2 }

  validates :from_workspace_id, :to_workspace_id, :workspace_list_id, presence: true
  validates :workspace_list_id, uniqueness: { conditions: -> { pending }, message: "already has a pending transfer" }
  validate  :workspaces_must_differ
  validate  :list_must_belong_to_from_workspace

  def facilitation = Facilitation.new(self)
  def accept!      = facilitation.accept
  def reject!      = facilitation.reject

  private

  def workspaces_must_differ
    return if from_workspace_id != to_workspace_id

    errors.add(:to_workspace, "must differ from source workspace")
  end

  def list_must_belong_to_from_workspace
    return unless list && from_workspace

    return if list.workspace_id == from_workspace_id

    errors.add(:list, "does not belong to source workspace")
  end
end
