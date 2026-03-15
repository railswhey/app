json.status :success
json.type :array
json.data { json.array!(@memberships, partial: "account/memberships/membership", as: :membership) }
