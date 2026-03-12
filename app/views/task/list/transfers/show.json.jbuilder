json.status :success
json.type :object
json.data { json.partial!("task/list/transfers/transfer", transfer: @transfer) }
