# frozen_string_literal: true

class Task::List::Transfer::Facilitation
  attr_reader :transfer

  def initialize(transfer)
    @transfer = transfer
  end

  def request(to:)
    return transfer unless transfer.save

    User::Notification::Delivery.new(transfer).transfer_requested(to: to)

    Task::ListTransferMailer.transfer_requested(transfer).deliver_later

    transfer
  end

  def accept(by:)
    return false unless transfer.pending? && transfer.persisted?
    return false unless transfer.to_account.owner_or_admin?(by)

    transfer.transaction do
      transfer.list.update!(account_id: transfer.to_account_id)

      transfer.update_columns(status: Task::List::Transfer.statuses[:accepted])

      Task::List::Transfer.where(task_list_id: transfer.task_list_id, status: :pending)
                          .where.not(id: transfer.id)
                          .update_all(status: Task::List::Transfer.statuses[:rejected])

      User::Notification::Delivery.new(transfer).transfer_accepted
    end

    true
  end

  def reject(by:)
    return false unless transfer.pending? && transfer.persisted?
    return false unless transfer.to_account.owner_or_admin?(by)

    transfer.transaction do
      transfer.update!(status: :rejected)

      User::Notification::Delivery.new(transfer).transfer_rejected
    end

    true
  end
end
