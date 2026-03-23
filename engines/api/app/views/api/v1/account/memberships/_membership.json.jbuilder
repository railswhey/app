json.extract! membership, :id, :role, :created_at, :updated_at
json.user do
  json.extract! membership.person, :id, :email, :username
end
