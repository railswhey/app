json.status :success
json.type :array
json.data { json.array!(@task_lists, partial: "task/lists/list", as: :list) }
json.url v1_task_lists_url(format: :json)
