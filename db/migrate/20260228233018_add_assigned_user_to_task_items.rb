class AddAssignedUserToTaskItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :task_items, :assigned_user,
                  foreign_key: { to_table: :users },
                  null: true, index: true
  end
end
