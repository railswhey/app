# frozen_string_literal: true

require "test_helper"

class Web::CurrentTest < ActiveSupport::TestCase
  test ".authorize! with user_id" do
    user = users(:one)

    create_task_list(member!(user).account, name: "Foo")

    Web::Current.authorize!(user_id: user.id)

    assert_predicate Web::Current, :authorized?

    assert_equal member!(user).account.id, Web::Current.account_id
    assert_equal member!(user).inbox.id, Web::Current.task_list_id

    assert_equal member!(user).account, Web::Current.account
    assert_equal member!(user).inbox, Web::Current.task_list
    assert_equal user, Web::Current.user

    assert_equal member!(user).workspace.lists, Web::Current.task_lists
    assert_equal 2, Web::Current.task_lists.size

    assert_predicate Web::Current, :user?
    assert_predicate Web::Current, :task_list_id?

    # ---

    user_id = User.maximum(:id) + 1

    Web::Current.authorize!(user_id:)

    assert_not_predicate Web::Current, :authorized?

    assert_nil Web::Current.user
    assert_nil Web::Current.account_id
    assert_nil Web::Current.task_list_id
  end

  test ".authorize! with user_id and account_id" do
    user = users(:one)
    account = accounts(:one)

    Web::Current.authorize!(user_id: user.id, account_id: account.id)

    assert_predicate Web::Current, :authorized?

    assert_equal user, Web::Current.user
    assert_equal account.id, Web::Current.account_id
    workspace = ::Workspace.find_by!(uuid: account.uuid)
    assert_equal workspace.inbox.id, Web::Current.task_list_id

    # ---

    Web::Current.authorize!(user_id: user.id, account_id: accounts(:two).id)

    assert_not_predicate Web::Current, :authorized?

    assert_equal user, Web::Current.user
    assert_nil Web::Current.account_id
    assert_nil Web::Current.task_list_id

    # ---

    user_id = User.maximum(:id) + 1

    Web::Current.authorize!(user_id:, account_id: account.id)

    assert_not_predicate Web::Current, :authorized?

    assert_nil Web::Current.user
    assert_nil Web::Current.account_id
    assert_nil Web::Current.task_list_id
  end

  test ".authorize! with user_id and task_list_id" do
    user = users(:one)
    account = member!(user).account
    task_list = create_task_list(account, name: "Foo")

    Web::Current.authorize!(user_id: user.id, task_list_id: task_list.id)

    assert_predicate Web::Current, :authorized?

    assert_equal user, Web::Current.user
    assert_equal task_list.id, Web::Current.task_list_id
    assert_equal account.id, Web::Current.account_id

    # ---

    Web::Current.authorize!(user_id: user.id, task_list_id: workspace_lists(:two_inbox).id)

    assert_not_predicate Web::Current, :authorized?

    assert_equal user, Web::Current.user
    assert_equal account.id, Web::Current.account_id
    assert_equal workspace_lists(:two_inbox).id, Web::Current.task_list_id

    # ---

    user_id = User.maximum(:id) + 1

    Web::Current.authorize!(user_id:, task_list_id: task_list.id)

    assert_not_predicate Web::Current, :authorized?

    assert_nil Web::Current.user
    assert_nil Web::Current.account_id
    assert_equal task_list.id, Web::Current.task_list_id
  end

  test ".authorize! with user_id, account_id, and task_list_id" do
    user = users(:one)
    account = accounts(:one)
    task_list = create_task_list(account, name: "Foo")

    Web::Current.authorize!(user_id: user.id, account_id: account.id, task_list_id: task_list.id)

    assert_predicate Web::Current, :authorized?

    assert_equal user, Web::Current.user
    assert_equal account.id, Web::Current.account_id
    assert_equal task_list.id, Web::Current.task_list_id

    # ---

    Web::Current.authorize!(user_id: user.id, account_id: accounts(:two).id, task_list_id: task_list.id)

    assert_not_predicate Web::Current, :authorized?

    assert_equal user, Web::Current.user
    assert_nil Web::Current.account_id
    assert_equal task_list.id, Web::Current.task_list_id

    # ---

    task_list_id = workspace_lists(:two_inbox).id

    Web::Current.authorize!(user_id: user.id, account_id: account.id, task_list_id:)

    assert_not_predicate Web::Current, :authorized?

    assert_equal user, Web::Current.user
    assert_equal account.id, Web::Current.account_id
    assert_equal task_list_id, Web::Current.task_list_id
  end
end
