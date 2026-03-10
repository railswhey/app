json.status :success
json.type :array
json.data { json.array!(@memberships, partial: "accounts/membership", as: :membership) }
