json.status :success
json.type :object
json.data { json.partial!("task/list_transfers/task_list_transfer", task_list_transfer: @transfer) }
