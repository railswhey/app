# frozen_string_literal: true

module UsersNotificationsConcern
  extend ActiveSupport::Concern

  def notifications
    @filter = params[:filter] || "all"
    @unread_count = Current.user.notifications.unread.count

    base = Current.user.notifications.chronological.includes(:notifiable)
    @notifications = case @filter
    when "unread"    then base.unread
    when "transfers" then base.where(action: %w[transfer_requested transfer_accepted transfer_rejected])
    when "invites"   then base.where(action: %w[invitation_received invitation_accepted])
    else base
    end.limit(50)

    render :notifications
  end

  def update_notification
    @notification = Current.user.notifications.find(params[:id])
    @notification.mark_read!
    redirect_to notifications_path, notice: "Marked as read."
  end

  def mark_all_notifications_read
    Current.user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end
end
