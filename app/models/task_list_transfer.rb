# frozen_string_literal: true

class TaskListTransfer < ApplicationRecord
  belongs_to :task_list
  belongs_to :from_account,   class_name: "Account"
  belongs_to :to_account,     class_name: "Account"
  belongs_to :transferred_by, class_name: "User"

  has_secure_token :token

  attr_accessor :to_user

  enum :status, { pending: 0, accepted: 1, rejected: 2 }

  def self.resolve_recipient(email)
    email = email.to_s.strip.downcase
    user = User.find_by(email: email)
    return [ nil, "No user found with that email." ] unless user
    return [ nil, "Target user has no account." ] unless user.account
    [ user, nil ]
  end

  validates :from_account_id, :to_account_id, :task_list_id, presence: true
  validates :task_list_id, uniqueness: { conditions: -> { where(status: :pending) },
                                         message: "already has a pending transfer" }
  validate  :accounts_must_differ
  validate  :task_list_must_belong_to_from_account

  after_create_commit :notify_recipient
  after_create_commit :send_transfer_email

  def accept!(user)
    return false unless pending?
    return false unless to_account.memberships.owner_or_admin.exists?(user: user)

    transaction do
      task_list.update!(account_id: to_account_id)
      update_columns(status: self.class.statuses[:accepted])

      TaskListTransfer.where(task_list_id: task_list_id, status: :pending)
                      .where.not(id: id)
                      .update_all(status: self.class.statuses[:rejected])

      Notification.create!(
        user:       transferred_by,
        notifiable: self,
        action:     "transfer_accepted"
      )
    end
    true
  end

  def reject!(user)
    return false unless pending?
    return false unless to_account.memberships.owner_or_admin.exists?(user: user)

    transaction do
      update!(status: :rejected)

      Notification.create!(
        user:       transferred_by,
        notifiable: self,
        action:     "transfer_rejected"
      )
    end
    true
  end

  private

  def accounts_must_differ
    errors.add(:to_account, "must differ from source account") if from_account_id == to_account_id
  end

  def task_list_must_belong_to_from_account
    return unless task_list && from_account
    unless task_list.account_id == from_account_id
      errors.add(:task_list, "does not belong to source account")
    end
  end

  def notify_recipient
    return unless to_user

    Notification.create!(user: to_user, notifiable: self, action: "transfer_requested")
  end

  def send_transfer_email
    Task::ListTransferMailer.transfer_requested(self).deliver_later
  end
end
