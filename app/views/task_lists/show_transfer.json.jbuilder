json.status :success
json.type :object
json.data { json.partial!("task_lists/task_list_transfer", task_list_transfer: @transfer) }
