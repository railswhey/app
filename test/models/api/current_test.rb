# frozen_string_literal: true

require "test_helper"

class API::CurrentTest < ActiveSupport::TestCase
  test ".authorize! with user_token" do
    user = users(:one)
    user_token = get_user_token(user)

    API::Current.authorize!(user_token:)

    assert_equal user, API::Current.user
    assert_equal member!(user).account.id, API::Current.account_id
    assert_equal member!(user).inbox.id, API::Current.task_list_id

    assert_predicate API::Current, :user?

    # ---

    API::Current.authorize!(user_token: SecureRandom.hex)

    assert_nil API::Current.user
    assert_nil API::Current.account_id
    assert_nil API::Current.task_list_id
  end

  test ".authorize! with user_token and task_list_id" do
    user = users(:one)
    account = member!(user).account
    task_list = create_task_list(account, name: "Foo")
    user_token = get_user_token(user)

    API::Current.authorize!(user_token:, task_list_id: task_list.id)

    assert_equal user, API::Current.user
    assert_equal task_list.id, API::Current.task_list_id
    assert_equal account.id, API::Current.account_id

    # ---

    API::Current.authorize!(user_token:, task_list_id: workspace_lists(:two_inbox).id)

    assert_equal user, API::Current.user
    assert_equal account.id, API::Current.account_id
    assert_equal workspace_lists(:two_inbox).id, API::Current.task_list_id

    # ---

    API::Current.authorize!(user_token: SecureRandom.hex, task_list_id: task_list.id)

    assert_nil API::Current.user
    assert_nil API::Current.account_id
    assert_equal task_list.id, API::Current.task_list_id
  end
end
