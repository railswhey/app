# frozen_string_literal: true

module TaskItemsHelper
  def link_to_task_item_filters
    style = "color: var(--text) !important;"

    all = { title: "All", path: task_list_items_path(Current.task_list_id), style: }
    completed = { title: "Completed", path: task_list_items_path(Current.task_list_id, filter: Workspace::Task::COMPLETED), style: }
    incomplete = { title: "Incomplete", path: task_list_items_path(Current.task_list_id, filter: Workspace::Task::INCOMPLETE), style: }

    filter_as = ->(options) {
      options.merge!(title: "#{options[:title]} (#{@task_items.size})", style: "color: #ffb300 !important; font-weight: 600;")
    }

    case params[:filter]
    when Workspace::Task::INCOMPLETE then filter_as[incomplete]
    when Workspace::Task::COMPLETED  then filter_as[completed]
    else filter_as[all]
    end

    safe_join([
      link_to(all[:title], all[:path], style: all[:style]),
      " | ",
      link_to(incomplete[:title], incomplete[:path], style: incomplete[:style]),
      " | ",
      link_to(completed[:title], completed[:path], style: completed[:style])
    ])
  end

  TASK_ITEMS_EMPTY = {
    "all" => { icon: "📭", title: "Your %{list} is clear!", message: "No tasks here yet. Add your first task to start tracking what needs be done." },
    Workspace::Task::COMPLETED => { icon: "🏁", title: "No completed tasks", message: "You don't have any completed tasks yet. Keep up the good work!" },
    Workspace::Task::INCOMPLETE => { icon: "🎉", title: "All done!", message: "You don't have any incomplete tasks. Great job!" }
  }.freeze

  def empty_task_items_message(filter = nil)
    data = TASK_ITEMS_EMPTY[filter] || TASK_ITEMS_EMPTY["all"]
    list_name = Current.task_list&.name || "Inbox"

    content_tag(:div, class: "empty-state") do
      safe_join([
        content_tag(:div, data[:icon], class: "empty-state-icon"),
        content_tag(:h3, data[:title] % { list: list_name }),
        content_tag(:p, data[:message]),
        (link_to("+ Add Your First Task", new_task_list_item_path(Current.task_list_id), class: "button") if filter.nil?)
      ].compact)
    end
  end
end
