json.status :success
json.type :array
json.data { json.array!(@invitations, partial: "accounts/invitation", as: :invitation) }
