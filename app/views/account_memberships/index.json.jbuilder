json.status :success
json.type :array
json.data { json.array!(@memberships, partial: "account_memberships/membership", as: :membership) }
