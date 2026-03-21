# frozen_string_literal: true

class Workspace::ListTransferMailer < ApplicationMailer
  default template_path: "workspace/mailers/list_transfer"

  def transfer_requested(transfer)
    @transfer        = transfer
    @to_account_name = params[:to_account_name]
    @review_url      = account_transfers_response_url(token: transfer.token)

    mail(
      to: params[:recipient_email],
      subject: "Transfer request: #{transfer.list.name}"
    )
  end
end
