class RenameNotificationsToUserNotifications < ActiveRecord::Migration[8.1]
  def change
    rename_table :notifications, :user_notifications

    reversible do |dir|
      dir.up do
        execute "UPDATE user_notifications SET notifiable_type = 'Account::Invitation' WHERE notifiable_type = 'Invitation'"
        execute "UPDATE user_notifications SET notifiable_type = 'Task::List::Transfer' WHERE notifiable_type = 'TaskListTransfer'"
      end
      dir.down do
        execute "UPDATE notifications SET notifiable_type = 'Invitation' WHERE notifiable_type = 'Account::Invitation'"
        execute "UPDATE notifications SET notifiable_type = 'TaskListTransfer' WHERE notifiable_type = 'Task::List::Transfer'"
      end
    end
  end
end
