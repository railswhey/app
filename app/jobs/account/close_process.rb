# frozen_string_literal: true

class Account::CloseProcess < ApplicationJob
  def perform(user)
    uuid = user.uuid

    Workspace.find_by!(uuid:).destroy!

    Account::Teardown.call(uuid:)

    user.destroy!

    [ :ok, user ]
  rescue ActiveRecord::ActiveRecordError => e
    [ :err, e ]
  end
end
