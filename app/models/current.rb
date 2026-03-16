# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :member

  delegate :account, :account?, :account_id, :account_id?, :owner_or_admin?,
           :user, :user?, :user_id, :user_id?, :user_token, :user_token?,
           :task_list, :task_list?, :task_list_id, :task_list_id?,
           :task_lists, :task_items, to: :member, allow_nil: true

  def member!(**options)
    reset

    self.member = Account::Member.authorize(options)
  end

  def member?
    member&.authorized? || false
  end
end
