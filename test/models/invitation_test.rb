# frozen_string_literal: true

require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @inviter = users(:one)
    @invitee_email = "invitee@example.com"
  end

  test "valid invitation" do
    inv = Invitation.new(account: @account, invited_by: @inviter, email: @invitee_email)
    assert inv.valid?
  end

  test "requires email" do
    inv = Invitation.new(account: @account, invited_by: @inviter)
    assert inv.invalid?
    assert inv.errors[:email].present?
  end

  test "requires valid email format" do
    inv = Invitation.new(account: @account, invited_by: @inviter, email: "not-an-email")
    assert inv.invalid?
    assert inv.errors[:email].present?
  end

  test "normalizes email to downcase and strips whitespace" do
    inv = Invitation.create!(account: @account, invited_by: @inviter, email: "  INVITEE@Example.COM  ")
    assert_equal "invitee@example.com", inv.email
  end

  test "uniqueness scoped to account_id" do
    Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    dup = Invitation.new(account: @account, invited_by: @inviter, email: @invitee_email)
    assert dup.invalid?
    assert dup.errors[:email].present?
  end

  test "same email can be invited to different accounts" do
    account2 = accounts(:two)
    Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    inv2 = Invitation.new(account: account2, invited_by: users(:two), email: @invitee_email)
    assert inv2.valid?
  end

  test "generates token automatically" do
    inv = Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    assert inv.token.present?
  end

  test "pending? returns true when not accepted" do
    inv = Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    assert inv.pending?
    assert_not inv.accepted?
  end

  test "pending scope returns unaccepted invitations" do
    inv = Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    assert_includes Invitation.pending, inv
    assert_not_includes Invitation.accepted, inv
  end

  test "accept! creates membership and marks invitation accepted" do
    inv = Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    new_user = User.create!(username: "invitee", email: @invitee_email, password: "password123", password_confirmation: "password123")

    assert inv.accept!(new_user)
    assert inv.reload.accepted?
    assert inv.accepted_at.present?
    assert @account.memberships.exists?(user: new_user)
  end

  test "accept! creates collaborator membership" do
    inv = Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    new_user = User.create!(username: "invitee", email: @invitee_email, password: "password123", password_confirmation: "password123")

    inv.accept!(new_user)
    membership = @account.memberships.find_by(user: new_user)
    assert membership.collaborator?
  end

  test "accept! returns false if already accepted" do
    inv = Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    inv.update_column(:accepted_at, Time.current)
    new_user = User.create!(username: "invitee", email: @invitee_email, password: "password123", password_confirmation: "password123")

    assert_not inv.accept!(new_user)
  end

  test "accepted scope returns accepted invitations" do
    inv = Invitation.create!(account: @account, invited_by: @inviter, email: @invitee_email)
    inv.update_column(:accepted_at, Time.current)
    assert_includes Invitation.accepted, inv
    assert_not_includes Invitation.pending, inv
  end
end
