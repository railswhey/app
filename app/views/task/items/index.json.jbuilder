json.status :success
json.type :array
json.data { json.array!(@task_items, partial: "task/items/item", as: :item) }
json.url task_list_items_url(Current.task_list_id, format: :json)
