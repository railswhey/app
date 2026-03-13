# frozen_string_literal: true

class Task::ListTransferMailer < ApplicationMailer
  default template_path: "task/mailers/list_transfer"

  def transfer_requested(transfer)
    @transfer = transfer
    @review_url = account_transfers_response_url(token: transfer.token)

    mail(
      to: transfer.to_account.owner.email,
      subject: "Transfer request: #{transfer.task_list.name}"
    )
  end
end
