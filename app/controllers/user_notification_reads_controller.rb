# frozen_string_literal: true

class UserNotificationReadsController < ApplicationController
  before_action :authenticate_user!

  def create
    Current.user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end
end
