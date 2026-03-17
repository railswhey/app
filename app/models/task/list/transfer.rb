# frozen_string_literal: true

class Task::List::Transfer < ApplicationRecord
  belongs_to :list, foreign_key: :task_list_id, class_name: "Task::List"
  belongs_to :to_account,     class_name: "Account"
  belongs_to :from_account,   class_name: "Account"
  belongs_to :transferred_by, class_name: "User"

  has_secure_token :token

  enum :status, { pending: 0, accepted: 1, rejected: 2 }

  def self.resolve_recipient(email)
    email = email.to_s.strip.downcase

    user = User.find_by(email:)

    return [ nil, "No user found with that email." ] unless user
    return [ nil, "Target user has no account." ] unless user.account

    [ user, nil ]
  end

  validates :from_account_id, :to_account_id, :task_list_id, presence: true
  validates :task_list_id, uniqueness: { conditions: -> { pending }, message: "already has a pending transfer" }
  validate  :accounts_must_differ
  validate  :list_must_belong_to_from_account

  def facilitation
    Facilitation.new(self)
  end

  def accept!(user)
    facilitation.accept(by: user)
  end

  def reject!(user)
    facilitation.reject(by: user)
  end

  private

  def accounts_must_differ
    errors.add(:to_account, "must differ from source account") if from_account_id == to_account_id
  end

  def list_must_belong_to_from_account
    return unless list && from_account

    unless list.account_id == from_account_id
      errors.add(:list, "does not belong to source account")
    end
  end
end
