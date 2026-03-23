json.status :success
json.type :object
json.data { json.partial!("task/lists/list", list: @task_list) }
json.url v1_task_list_url(@task_list, format: :json)
