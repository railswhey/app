json.status :success
json.type :array
json.data { json.array!(@task_items, partial: "task/items/item", as: :item) }
json.url v1_task_list_items_url(current.task_list_id, format: :json)
