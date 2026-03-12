json.status :success
json.type :object
json.data { json.partial!("task/items/item", item: @task_item) }
json.url task_list_item_url(@task_item.task_list_id, @task_item, format: :json)
