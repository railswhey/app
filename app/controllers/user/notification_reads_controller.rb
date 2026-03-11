# frozen_string_literal: true

class User::NotificationReadsController < ApplicationController
  before_action :authenticate_user!

  def create
    Current.user.notifications.unread.update_all(read_at: Time.current)
    redirect_to user_notifications_path, notice: "All notifications marked as read."
  end
end
