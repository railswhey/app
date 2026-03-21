# frozen_string_literal: true

class Workspace::List::Transfer::Facilitation
  attr_reader :transfer

  def initialize(transfer)
    @transfer = transfer
  end

  def request
    return transfer unless transfer.save

    transfer
  end

  def accept
    return false unless actionable?

    transfer.transaction do
      move_list!
      mark_accepted!
      reject_competing!
    end

    true
  end

  def reject
    return false unless actionable?

    transfer.transaction do
      transfer.update!(status: :rejected)
    end

    true
  end

  private

  def actionable?
    transfer.pending? && transfer.persisted?
  end

  def move_list!
    transfer.list.update!(workspace_id: transfer.to_workspace_id)
  end

  def mark_accepted!
    transfer.update_columns(status: Workspace::List::Transfer.statuses[:accepted])
  end

  def reject_competing!
    Workspace::List::Transfer.where(workspace_list_id: transfer.workspace_list_id, status: :pending)
                             .where.not(id: transfer.id)
                             .update_all(status: Workspace::List::Transfer.statuses[:rejected])
  end
end
