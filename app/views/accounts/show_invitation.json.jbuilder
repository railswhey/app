json.status :success
json.type :object
json.data { json.partial!("accounts/invitation", invitation: @invitation) }
