# frozen_string_literal: true

class Web::User::Notification::InboxController < Web::BaseController
  before_action :authenticate_user!

  def index
    @filter = params[:filter] || "all"

    @unread_count = current.user.notifications.unread.count

    @notifications = current.user.notifications
      .chronological
      .includes(:notifiable)
      .filter_by(@filter)
      .limit(50)
  end

  def update
    @notification = current.user.notifications.find(params[:id])

    @notification.mark_read!

    redirect_to user_notification_inbox_index_path, notice: "Marked as read."
  end
end
