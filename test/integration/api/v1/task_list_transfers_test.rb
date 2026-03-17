# frozen_string_literal: true

require "test_helper"

class APIV1TaskListTransfersTest < ActionDispatch::IntegrationTest
  test "create responds with error when target user not found" do
    sender = users(:one)
    list = create_task_list(member!(sender).account, name: "Transferable")

    post(
      api_v1_adapter.task__list_transfer_form_url(list, format: :json),
      params: { task_list_transfer: { to_email: "nonexistent@example.com" } },
      headers: api_v1_adapter.authorization_header(sender)
    )

    api_v1_adapter.assert_response_with_failure(:unprocessable_entity)
  end

  test "create responds with error when target user has no account" do
    sender = users(:one)
    list = create_task_list(member!(sender).account, name: "Transferable")

    # User.create! without Registration gives a bare user with no account
    bare_user = User.create!(username: "bareuser", email: "bare@example.com", password: "password123")

    post(
      api_v1_adapter.task__list_transfer_form_url(list, format: :json),
      params: { task_list_transfer: { to_email: bare_user.email } },
      headers: api_v1_adapter.authorization_header(sender)
    )

    api_v1_adapter.assert_response_with_failure(:unprocessable_entity)
  end

  test "update responds with 401 when not authenticated" do
    transfer = create_transfer

    patch(
      api_v1_adapter.task__list_transfer_url(transfer.token, format: :json),
      params: { action_type: "accept" }
    )

    assert_response :unauthorized
  end

  test "new responds with 404 when task list not found via JSON" do
    user = users(:one)
    member!(user)

    get(
      api_v1_adapter.new_task__list_transfer_url(99_999_999, format: :json),
      headers: api_v1_adapter.authorization_header(user)
    )

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "show responds with 404 when transfer token invalid via JSON" do
    get(
      api_v1_adapter.show_task__list_transfer_url("invalid-token", format: :json)
    )

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "create responds with 403 when user is not owner or admin via JSON" do
    collaborator = users(:two)
    account = member!(collaborator).account
    list = create_task_list(account, name: "Transferable")
    # Downgrade user two's own membership to collaborator so the guard fires
    account.memberships.find_by(user: collaborator).update!(role: :collaborator)

    post(
      api_v1_adapter.task__list_transfer_form_url(list, format: :json),
      params: { task_list_transfer: { to_email: "someone@example.com" } },
      headers: api_v1_adapter.authorization_header(collaborator)
    )

    api_v1_adapter.assert_response_with_failure(:forbidden)
  end

  private

  def create_transfer(from_user: users(:one), to_user: users(:two))
    list = create_task_list(member!(from_user).account, name: "Transfer Me")
    Task::List::Transfer.create!(
      list: list,
      from_account: from_user.account,
      to_account: to_user.account,
      transferred_by: from_user
    )
  end
end
