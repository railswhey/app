# frozen_string_literal: true

class Web::User::Notification::ReadsController < Web::BaseController
  before_action :authenticate_user!

  def create
    Current.user.notifications.unread.update_all(read_at: Time.current)
    redirect_to user_notification_inbox_index_path, notice: "All notifications marked as read."
  end
end
