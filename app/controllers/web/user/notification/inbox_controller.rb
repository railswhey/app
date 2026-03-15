# frozen_string_literal: true

class Web::User::Notification::InboxController < Web::BaseController
  before_action :authenticate_user!

  def index
    @filter = params[:filter] || "all"
    @unread_count = Current.user.notifications.unread.count

    base = Current.user.notifications.chronological.includes(:notifiable)
    @notifications = case @filter
    when "unread"    then base.unread
    when "transfers" then base.where(action: %w[transfer_requested transfer_accepted transfer_rejected])
    when "invites"   then base.where(action: %w[invitation_received invitation_accepted])
    else base
    end.limit(50)
  end

  def update
    @notification = Current.user.notifications.find(params[:id])
    @notification.mark_read!
    redirect_to user_notification_inbox_index_path, notice: "Marked as read."
  end
end
