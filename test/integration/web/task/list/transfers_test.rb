# frozen_string_literal: true

require "test_helper"

class WebTaskListTransfersTest < ActionDispatch::IntegrationTest
  # ── New (transfer form) ──────────────────────────────────────────────────

  test "guest cannot access transfer form" do
    user = users(:one)
    list = create_task_list(member!(user).account, name: "Transferable")

    get web_adapter.new_task__list_transfer_url(list)

    assert_redirected_to web_adapter.new_user__session_url
  end

  test "owner can access transfer form" do
    user = users(:one)
    list = create_task_list(member!(user).account, name: "Transferable")

    web_adapter.sign_in(user)

    get web_adapter.new_task__list_transfer_url(list)

    assert_response :ok
    assert_select "h2", /Transfer List/
    assert_select "input[name='task_list_transfer[to_email]']"
  end

  # ── Create (send transfer request) ───────────────────────────────────────

  test "collaborator cannot access transfer form" do
    owner = users(:one)
    account = member!(owner).account
    list = create_task_list(account, name: "Transferable")
    collaborator = users(:two)
    member!(collaborator)
    account.memberships.create!(user: collaborator, role: :collaborator)

    web_adapter.sign_in(collaborator)
    # Switch to owner's account so Current.account resolves and guard can fire
    post web_adapter.switch__account_url(account)

    get web_adapter.new_task__list_transfer_url(list)
    # guard fires → home_path uses Current.task_list_id = list.id (from params)
    assert_redirected_to web_adapter.task__items_url(list)
  end

  test "transfer fails when target user has no account" do
    sender = users(:one)
    list = create_task_list(member!(sender).account, name: "Transferable")

    # User.create! triggers an after_create that creates an account — destroy it to simulate no-account
    bare_user = User.create!(username: "bareuser", email: "bare@example.com", password: "password123")
    bare_user.memberships.destroy_all

    web_adapter.sign_in(sender)

    post web_adapter.task__list_transfer_form_url(list), params: {
      task_list_transfer: { to_email: bare_user.email }
    }

    assert_redirected_to web_adapter.new_task__list_transfer_url(list)
    follow_redirect!
    assert_select ".notice-text", /no account/
  end

  test "transfer form for non-existent list redirects home" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.new_task__list_transfer_url(99_999_999)
    assert_response :redirect
    follow_redirect!
    assert_select ".notice-text", /not found/i
  end

  test "show transfer with invalid token redirects home" do
    get web_adapter.show_task__list_transfer_url("invalid-token-xyz-404")
    assert_redirected_to task_lists_path
  end

  test "unauthenticated user updating transfer is redirected to sign in" do
    transfer = create_transfer

    patch web_adapter.task__list_transfer_url(transfer.token), params: { action_type: "accept" }

    assert_response :redirect
    assert response.location.include?(web_adapter.new_user__session_url)
  end

  test "update with unknown action_type redirects back to show" do
    receiver = users(:two)
    transfer = create_transfer(to_user: receiver)

    web_adapter.sign_in(receiver)

    patch web_adapter.task__list_transfer_url(transfer.token), params: { action_type: "explode" }
    assert_redirected_to web_adapter.show_task__list_transfer_url(transfer.token)
  end

  test "transfer fails when target user does not exist" do
    user = users(:one)
    list = create_task_list(member!(user).account, name: "Transferable")

    web_adapter.sign_in(user)

    post web_adapter.task__list_transfer_form_url(list), params: {
      task_list_transfer: { to_email: "nonexistent@example.com" }
    }

    assert_redirected_to web_adapter.new_task__list_transfer_url(list)
    follow_redirect!
    assert_select ".notice-text", /No user found/
  end

  test "transfer fails when sending to self" do
    user = users(:one)
    list = create_task_list(member!(user).account, name: "Transferable")

    web_adapter.sign_in(user)

    post web_adapter.task__list_transfer_form_url(list), params: {
      task_list_transfer: { to_email: user.email }
    }

    # Should fail validation (accounts must differ)
    assert_response :unprocessable_entity
  end

  test "owner sends a transfer request successfully" do
    sender = users(:one)
    receiver = users(:two)
    list = create_task_list(member!(sender).account, name: "Transferable")

    web_adapter.sign_in(sender)

    assert_difference "TaskListTransfer.count", 1 do
      post web_adapter.task__list_transfer_form_url(list), params: {
        task_list_transfer: { to_email: receiver.email }
      }
    end

    transfer = TaskListTransfer.last
    assert transfer.pending?
    assert_equal list, transfer.task_list
    assert_equal sender.account, transfer.from_account
    assert_equal receiver.account, transfer.to_account

    assert_redirected_to web_adapter.task__list_url(list)
    follow_redirect!
    assert_select ".notice-text", /Transfer request sent/
  end

  test "transfer request sends notification and email to receiver" do
    sender = users(:one)
    receiver = users(:two)
    list = create_task_list(member!(sender).account, name: "Transferable")

    web_adapter.sign_in(sender)

    assert_enqueued_emails 1 do
      assert_difference "Notification.count", 1 do
        post web_adapter.task__list_transfer_form_url(list), params: {
          task_list_transfer: { to_email: receiver.email }
        }
      end
    end

    notification = Notification.last
    assert_equal receiver, notification.user
    assert_equal "transfer_requested", notification.action
  end

  # ── Show (transfer details) ──────────────────────────────────────────────

  test "anyone can view a transfer by token" do
    transfer = create_transfer

    get web_adapter.show_task__list_transfer_url(transfer.token)

    assert_response :ok
    assert_select ".detail-card"
  end

  test "unauthenticated user sees sign in and create account links" do
    transfer = create_transfer

    get web_adapter.show_task__list_transfer_url(transfer.token)

    assert_response :ok
    assert_select "a", /Sign in/
    assert_select "a", /Create account/
  end

  # ── Update (accept / reject) ─────────────────────────────────────────────

  test "receiver accepts a transfer" do
    receiver = users(:two)
    transfer = create_transfer(to_user: receiver)
    list = transfer.task_list

    web_adapter.sign_in(receiver)

    patch web_adapter.task__list_transfer_url(transfer.token), params: { action_type: "accept" }

    assert_redirected_to web_adapter.task__items_url(receiver.inbox)
    follow_redirect!
    assert_select ".notice-text", /transferred successfully/

    transfer.reload
    assert transfer.accepted?
    assert_equal receiver.account, list.reload.account
  end

  test "receiver rejects a transfer" do
    receiver = users(:two)
    transfer = create_transfer(to_user: receiver)

    web_adapter.sign_in(receiver)

    patch web_adapter.task__list_transfer_url(transfer.token), params: { action_type: "reject" }

    assert_redirected_to web_adapter.task__items_url(receiver.inbox)
    follow_redirect!
    assert_select ".notice-text", /rejected/

    assert transfer.reload.rejected?
  end

  test "sender cannot accept their own transfer" do
    sender = users(:one)
    transfer = create_transfer(from_user: sender)

    web_adapter.sign_in(sender)

    patch web_adapter.task__list_transfer_url(transfer.token), params: { action_type: "accept" }

    # Should fail — sender is not in to_account
    assert_redirected_to web_adapter.show_task__list_transfer_url(transfer.token)
    follow_redirect!
    assert_select ".notice-text", /Could not process/
  end

  # ── Move task via modal ──────────────────────────────────────────────────

  test "user moves a task to another list" do
    user = users(:one)
    account = member!(user).account
    source = account.task_lists.inbox.first
    target = create_task_list(account, name: "Target")
    task = create_task(user, name: "Movable", task_list: source)

    web_adapter.sign_in(user)

    put web_adapter.move_task__item_url(source, task, target_list_id: target.id)

    assert_redirected_to web_adapter.task__items_url(source)
    follow_redirect!
    assert_select ".notice-text", /moved to "Target"/

    assert_equal target, task.reload.task_list
  end

  test "move fails with invalid target list" do
    user = users(:one)
    account = member!(user).account
    source = account.task_lists.inbox.first
    task = create_task(user, name: "Movable", task_list: source)

    web_adapter.sign_in(user)

    put web_adapter.move_task__item_url(source, task, target_list_id: 999999)

    assert_redirected_to web_adapter.task__items_url(source)
    follow_redirect!
    assert_select ".notice-text", /not found/
  end

  # ── Settings hub ─────────────────────────────────────────────────────────

  test "user can access settings hub" do
    user = users(:one)
    member!(user)

    web_adapter.sign_in(user)

    get web_adapter.settings__url

    assert_response :ok
    assert_select "h2", "Settings"
    assert_select ".settings-card", minimum: 3
  end

  # ── Return-to flow ──────────────────────────────────────────────────────

  test "sign in with return_to redirects to the given path" do
    user = users(:one)
    member!(user)
    transfer = create_transfer(from_user: users(:two), to_user: user)
    return_path = web_adapter.show_task__list_transfer_path(transfer.token)

    post web_adapter.user__sessions_url, params: {
      user: { email: user.email, password: "123123123" },
      return_to: return_path
    }

    assert_redirected_to return_path
  end

  test "sign up with return_to redirects to the given path" do
    transfer = create_transfer
    return_path = web_adapter.show_task__list_transfer_path(transfer.token)

    post web_adapter.user__registrations_url, params: {
      user: {
        username: "newbie",
        email: "newbie@example.com",
        password: "123123123",
        password_confirmation: "123123123"
      },
      return_to: return_path
    }

    assert_redirected_to return_path
  end

  private

  def create_transfer(from_user: users(:one), to_user: users(:two))
    list = create_task_list(member!(from_user).account, name: "Transfer Me")

    TaskListTransfer.create!(
      task_list: list,
      from_account: from_user.account,
      to_account: to_user.account,
      transferred_by: from_user
    )
  end
end
