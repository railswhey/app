# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :context
  attribute :scope

  delegate :user, :account, :workspace,
           :user?, :account?, :workspace?,
           :account_id, :owner_or_admin?,
           to: :context, allow_nil: true

  delegate :task_lists, :tasks,
           :task_list, :task_list?,
           :task_list_id, :task_list_id?,
           to: :scope, allow_nil: true

  def authorize!(user_id: nil, user_token: nil, account_id: nil, task_list_id: nil)
    reset

    self.context = Resolver.call(user_id:, user_token:, account_id:)

    self.scope   = Scope.new(workspace: context.workspace, task_list_id:)
  end

  def authorized?
    context.authorized? && task_list.present?
  end
end
