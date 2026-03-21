# frozen_string_literal: true

class Account::CloseProcess < ApplicationJob
  def perform(user)
    uuid = user.uuid

    ActiveRecord::Base.transaction do
      Workspace.find_by!(uuid:).destroy!

      Account::Teardown.call(uuid:)

      user.destroy!
    end

    [ :ok, user ]
  end
end
