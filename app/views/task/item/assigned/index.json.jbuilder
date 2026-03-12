json.status :success
json.type :array
json.data { json.array!(@task_items, partial: "task/items/item", as: :item) }
json.filter @filter
json.counts @item_counts
json.url my_tasks_url(format: :json)
