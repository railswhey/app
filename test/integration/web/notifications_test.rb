# frozen_string_literal: true

require "test_helper"

class WebNotificationsTest < ActionDispatch::IntegrationTest
  # ── Index ────────────────────────────────────────────────────────────────

  test "guest cannot access notifications" do
    get web_adapter.notifications__url
    web_adapter.assert_unauthorized_access
  end

  test "user views notifications page" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.notifications__url
    assert_response :ok
    assert_select "h1", /Notifications/
  end

  test "user sees unread notifications" do
    user = users(:one)
    member!(user)
    create_notification(user, action: "transfer_requested")
    web_adapter.sign_in(user)

    get web_adapter.notifications__url
    assert_response :ok
    assert_select ".notification-unread", 1
  end

  test "user filters by unread" do
    user = users(:one)
    member!(user)
    create_notification(user, action: "transfer_requested")
    create_notification(user, action: "invitation_received", read: true)
    web_adapter.sign_in(user)

    get web_adapter.notifications__url(filter: "unread")
    assert_response :ok
    assert_select ".notification-card", 1
  end

  test "user filters by transfers" do
    user = users(:one)
    member!(user)
    create_notification(user, action: "transfer_requested")
    create_notification(user, action: "invitation_received")
    web_adapter.sign_in(user)

    get web_adapter.notifications__url(filter: "transfers")
    assert_response :ok
    assert_select ".notification-card", 1
  end

  test "user filters by invites" do
    user = users(:one)
    member!(user)
    create_notification(user, action: "transfer_requested")
    create_notification(user, action: "invitation_received")
    web_adapter.sign_in(user)

    get web_adapter.notifications__url(filter: "invites")
    assert_response :ok
    assert_select ".notification-card", 1
  end

  # ── Mark read ────────────────────────────────────────────────────────────

  test "user marks a notification as read" do
    user = users(:one)
    member!(user)
    notification = create_notification(user, action: "transfer_requested")
    web_adapter.sign_in(user)

    put web_adapter.notification__url(notification)
    assert_redirected_to web_adapter.notifications__url

    assert notification.reload.read?
  end

  test "user marks all notifications as read" do
    user = users(:one)
    member!(user)
    n1 = create_notification(user, action: "transfer_requested")
    n2 = create_notification(user, action: "invitation_received")
    web_adapter.sign_in(user)

    put web_adapter.mark_all_read__notifications_url
    assert_redirected_to web_adapter.notifications__url

    assert n1.reload.read?
    assert n2.reload.read?
  end

  # ── Notification creation via transfers ──────────────────────────────────

  test "creating a transfer notifies the receiver" do
    sender = users(:one)
    receiver = users(:two)
    list = create_task_list(member!(sender).account, name: "For Transfer")
    web_adapter.sign_in(sender)

    assert_difference "receiver.notifications.count", 1 do
      post web_adapter.task__list_transfer_form_url(list), params: {
        task_list_transfer: { to_email: receiver.email }
      }
    end

    notification = receiver.notifications.last
    assert_equal "transfer_requested", notification.action
    assert_equal "TaskListTransfer", notification.notifiable_type
  end

  test "accepting a transfer notifies the sender" do
    sender = users(:one)
    receiver = users(:two)
    transfer = create_transfer(from_user: sender, to_user: receiver)
    web_adapter.sign_in(receiver)

    assert_difference "sender.notifications.count", 1 do
      patch web_adapter.task__list_transfer_url(transfer.token), params: { action_type: "accept" }
    end

    assert_equal "transfer_accepted", sender.notifications.last.action
  end

  test "rejecting a transfer notifies the sender" do
    sender = users(:one)
    receiver = users(:two)
    transfer = create_transfer(from_user: sender, to_user: receiver)
    web_adapter.sign_in(receiver)

    assert_difference "sender.notifications.count", 1 do
      patch web_adapter.task__list_transfer_url(transfer.token), params: { action_type: "reject" }
    end

    assert_equal "transfer_rejected", sender.notifications.last.action
  end

  # ── Notification creation via invitations ────────────────────────────────

  test "creating an invitation notifies the invitee if they have an account" do
    inviter = users(:one)
    invitee = users(:two)
    member!(inviter)

    web_adapter.sign_in(inviter)

    assert_difference "invitee.notifications.count", 1 do
      post web_adapter.account__invitations_url, params: { invitation: { email: invitee.email } }
    end

    notification = invitee.notifications.last
    assert_equal "invitation_received", notification.action
    assert_equal "Invitation", notification.notifiable_type
  end

  test "accepting an invitation notifies the inviter" do
    inviter = users(:one)
    invitee = users(:two)
    member!(inviter)
    member!(invitee)
    invitation = inviter.account.invitations.create!(email: invitee.email, invited_by: inviter)

    web_adapter.sign_in(invitee)

    assert_difference "inviter.notifications.count", 1 do
      patch web_adapter.accept__invitation_url(invitation.token)
    end

    assert_equal "invitation_accepted", inviter.notifications.last.action
  end

  # ── Badge in sidebar ─────────────────────────────────────────────────────

  test "sidebar shows notification badge when unread exist" do
    user = users(:one)
    member!(user)
    create_notification(user, action: "transfer_requested")
    web_adapter.sign_in(user)

    get web_adapter.task__lists_url
    assert_response :ok
    assert_select ".notification-badge", "1"
  end

  private

  def create_transfer(from_user:, to_user:)
    list = create_task_list(member!(from_user).account, name: "Transfer Me")
    TaskListTransfer.create!(
      task_list: list,
      from_account: from_user.account,
      to_account: to_user.account,
      transferred_by: from_user
    )
  end

  def create_notification(user, action:, read: false)
    # Use an invitation as a generic notifiable
    invitation = user.account.invitations.create!(email: "notif-#{SecureRandom.hex(4)}@example.com", invited_by: user)
    Notification.create!(
      user: user,
      notifiable: invitation,
      action: action,
      read_at: read ? Time.current : nil
    )
  end
end
