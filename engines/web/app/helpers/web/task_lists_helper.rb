# frozen_string_literal: true

module Web
  module TaskListsHelper
    def task_lists_selector
      safe_join([
        tag.br,
        select_tag(
          "task_list",
          options_from_collection_for_select(current.task_lists, "id", "name", current.task_list_id),
          style: "width: 97%;",
          onchange: "Turbo.visit(`/task/lists/${this.value}/items`)"
        )
      ])
    end
  end
end
