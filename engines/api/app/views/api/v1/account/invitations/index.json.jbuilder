json.status :success
json.type :array
json.data { json.array!(@invitations, partial: "account/invitations/invitation", as: :invitation) }
