# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :require_guest_access!, except: %i[
    destroy destroy_session
    edit_token update_token
    edit_profile update_profile
    settings
    notifications update_notification mark_all_notifications_read
  ]
  before_action :authenticate_user!, only: %i[
    destroy destroy_session
    edit_token update_token
    edit_profile update_profile
    settings
    notifications update_notification mark_all_notifications_read
  ]
  before_action :set_user_by_token, only: %i[edit_password update_password]

  include UsersRegistrationConcern
  include UsersSessionsConcern
  include UsersPasswordsConcern
  include UsersTokensConcern
  include UsersProfileConcern
  include UsersNotificationsConcern
  include UsersAccountDeletionConcern
  include UsersSettingsConcern
end
