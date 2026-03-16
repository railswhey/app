class RenameCommentsToTaskComments < ActiveRecord::Migration[8.1]
  def change
    rename_table :comments, :task_comments

    reversible do |dir|
      dir.up do
        execute "UPDATE task_comments SET commentable_type = 'Task::Item' WHERE commentable_type = 'TaskItem'"
        execute "UPDATE task_comments SET commentable_type = 'Task::List' WHERE commentable_type = 'TaskList'"
      end
      dir.down do
        execute "UPDATE comments SET commentable_type = 'TaskItem' WHERE commentable_type = 'Task::Item'"
        execute "UPDATE comments SET commentable_type = 'TaskList' WHERE commentable_type = 'Task::List'"
      end
    end
  end
end
