json.status :failure
json.type :object
json.data do
  json.message message
  json.details(local_assigns.fetch(:details, {}))
end
