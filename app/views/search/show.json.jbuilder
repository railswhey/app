json.status :success
json.type :object
json.query @query
json.data do
  json.task_items @task_items, partial: "task_items/task_item", as: :task_item
  json.task_lists @task_lists, partial: "task_lists/task_list", as: :task_list
end
json.url search_url(format: :json)
