json.status :success
json.type :object
json.query @query
json.data do
  json.task_items @results.task_items, partial: "task/items/item", as: :item
  json.task_lists @results.task_lists, partial: "task/lists/list", as: :list
end
json.url v1_account_search_url(format: :json)
