# frozen_string_literal: true

class Web::Current < ActiveSupport::CurrentAttributes
  attribute :context
  attribute :scope

  delegate :user, :account, :workspace,
           :user?, :account_id, :owner_or_admin?,
           to: :context, allow_nil: true

  delegate :task_lists, :tasks,
           :task_list, :task_list_id, :task_list_id?,
           to: :scope, allow_nil: true

  def authorize!(user_id: nil, account_id: nil, task_list_id: nil)
    reset

    self.context = ::Current::Resolver.call(user_id:, account_id:)
    self.scope   = ::Current::Scope.new(workspace: context.workspace, task_list_id:)
  end

  def authorized?
    context.authorized? && task_list.present?
  end
end
