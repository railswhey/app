json.status :success
json.type :object
json.data { json.partial!("account/transfers/responses/response", transfer: @transfer) }
