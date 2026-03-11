# frozen_string_literal: true

module TaskItemsHelper
  def task_lists_selector
    safe_join([
      tag.br,
      select_tag(
        "task_list",
        options_from_collection_for_select(Current.task_lists, "id", "name", Current.task_list_id),
        style: "width: 97%;",
        onchange: "Turbo.visit(`/task/lists/${this.value}/items`)"
      )
    ])
  end

  def link_to_task_item_filters
    style = "color: var(--text) !important;"

    all = { title: "All", path: task_list_items_path(Current.task_list_id), style: }
    completed = { title: "Completed", path: task_list_items_path(Current.task_list_id, filter: "completed"), style: }
    incomplete = { title: "Incomplete", path: task_list_items_path(Current.task_list_id, filter: "incomplete"), style: }

    case params[:filter]
    when "incomplete" then set_current_task_items_filter(incomplete)
    when "completed" then set_current_task_items_filter(completed)
    else set_current_task_items_filter(all)
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
    "completed" => { icon: "🏁", title: "No completed tasks", message: "You don't have any completed tasks yet. Keep up the good work!" },
    "incomplete" => { icon: "🎉", title: "All done!", message: "You don't have any incomplete tasks. Great job!" }
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

  private

  def set_current_task_items_filter(options)
    options.merge!(title: "#{options[:title]} (#{@task_items.size})", style: "color: #ffb300 !important; font-weight: 600;")
  end
end
