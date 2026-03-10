json.status :success
json.type :object
json.data { json.partial!("account_invitations/invitation", invitation: @invitation) }
