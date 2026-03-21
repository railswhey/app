json.extract!(transfer, :id, :token, :status, :created_at, :updated_at)
json.task_list_id    transfer.workspace_list_id
json.from_account_id transfer.from_workspace_id
json.to_account_id   transfer.to_workspace_id
