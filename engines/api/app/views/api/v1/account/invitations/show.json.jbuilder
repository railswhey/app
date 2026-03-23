json.status :success
json.type :object
json.data { json.partial!("account/invitations/invitation", invitation: @invitation) }
