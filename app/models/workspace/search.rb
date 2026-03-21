# frozen_string_literal: true

class Workspace::Search
  Results = Data.define(:task_lists, :task_items, :comments)

  attr_reader :workspace

  def initialize(workspace)
    @workspace = workspace
  end

  def empty
    Results.new(task_lists: Workspace::List.none, task_items: Workspace::Task.none, comments: Workspace::Comment.none)
  end

  def by(query)
    query = query.to_s.strip

    return empty if query.size <= 1

    Results.new(
      task_lists: workspace.lists.search(query).limit(10),
      task_items: workspace.tasks.search(query).includes(:list).order(created_at: :desc).limit(20),
      comments:   Workspace::Comment.for(workspace:).search(query).includes(:member, :commentable).order(created_at: :desc).limit(10)
    )
  end
end
