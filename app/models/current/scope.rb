# frozen_string_literal: true

class Current::Scope
  attr_reader :task_list_id

  def initialize(workspace:, task_list_id: nil)
    @workspace    = workspace
    @task_list_id = task_list_id || workspace&.inbox&.id
  end

  def task_list_id? = task_list_id.present?

  def task_lists = workspace&.lists
  def task_list? = task_list.present?
  def task_list  = @task_list ||= task_lists.find_by(id: task_list_id)

  def tasks = task_list&.tasks || ::Workspace::Task.none

  private

  attr_reader :workspace
end
