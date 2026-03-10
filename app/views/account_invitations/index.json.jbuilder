json.status :success
json.type :array
json.data { json.array!(@invitations, partial: "account_invitations/invitation", as: :invitation) }
