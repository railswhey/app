# frozen_string_literal: true

require "test_helper"

class WebInvitationsTest < ActionDispatch::IntegrationTest
  # ── Index ────────────────────────────────────────────────────────────────

  test "guest cannot list invitations" do
    get web_adapter.account__invitations_url
    web_adapter.assert_unauthorized_access
  end

  test "owner lists invitations" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.account__invitations_url
    assert_response :ok
  end

  # ── New ──────────────────────────────────────────────────────────────────

  test "owner accesses new invitation form" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.new_account__invitation_url
    assert_response :ok
  end

  # ── Create ───────────────────────────────────────────────────────────────

  test "owner sends an invitation" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    assert_difference "Invitation.count", 1 do
      post web_adapter.account__invitations_url, params: { invitation: { email: "newguy@example.com" } }
    end

    assert_redirected_to web_adapter.account__url
    follow_redirect!
    assert_select ".notice-text", /Invitation sent/
  end

  test "invitation fails with invalid email" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    assert_no_difference "Invitation.count" do
      post web_adapter.account__invitations_url, params: { invitation: { email: "bad" } }
    end

    assert_response :unprocessable_entity
  end

  # ── Show (token-based) ──────────────────────────────────────────────────

  test "anyone can view a pending invitation" do
    invitation = create_invitation
    get web_adapter.show__invitation_url(invitation.token)
    assert_response :ok
  end

  test "accepted invitation redirects to sign in" do
    invitation = create_invitation
    invitation.accept!(users(:two))

    get web_adapter.show__invitation_url(invitation.token)
    assert_redirected_to web_adapter.new_user__session_url
  end

  test "existing member sees already a member notice" do
    user = users(:one)
    member!(user)
    invitation = create_invitation

    web_adapter.sign_in(user)

    get web_adapter.show__invitation_url(invitation.token)
    assert_redirected_to web_adapter.task__items_url(user.inbox)
  end

  # ── Accept ───────────────────────────────────────────────────────────────

  test "user accepts an invitation" do
    inviter = users(:one)
    receiver = users(:two)
    member!(inviter)
    member!(receiver)
    invitation = create_invitation

    web_adapter.sign_in(receiver)

    patch web_adapter.accept__invitation_url(invitation.token)
    assert_redirected_to web_adapter.task__items_url(receiver.inbox)
    follow_redirect!
    assert_select ".notice-text", /joined/

    assert invitation.reload.accepted?
  end

  test "unauthenticated user is redirected to sign in" do
    invitation = create_invitation

    patch web_adapter.accept__invitation_url(invitation.token)
    # Redirects to sign in with return_to
    assert_response :redirect
    assert response.location.start_with?(web_adapter.new_user__session_url)
  end

  test "accepting an already-accepted invitation redirects to sign in" do
    invitation = create_invitation
    invitation.accept!(users(:two))

    web_adapter.sign_in(users(:two))

    patch web_adapter.accept__invitation_url(invitation.token)
    assert_redirected_to web_adapter.new_user__session_url
  end

  test "unauthenticated user accepting invitation is redirected to sign in" do
    invitation = create_invitation

    patch web_adapter.accept__invitation_url(invitation.token)
    assert_response :redirect
    assert response.location.include?(web_adapter.new_user__session_url)
  end

  test "collaborator cannot manage invitations" do
    owner = users(:one)
    collaborator = users(:two)
    member!(owner).account.memberships.create!(user: collaborator, role: :collaborator)

    web_adapter.sign_in(collaborator)

    post web_adapter.account__invitations_url, params: { invitation: { email: "x@x.com" } }
    assert_redirected_to web_adapter.account__url
  end

  # ── Destroy ──────────────────────────────────────────────────────────────

  test "owner revokes an invitation" do
    user = users(:one)
    member!(user)
    invitation = create_invitation

    web_adapter.sign_in(user)

    assert_difference "Invitation.count", -1 do
      delete web_adapter.account__invitation_url(invitation)
    end

    assert_redirected_to web_adapter.account__url
  end

  private

  def create_invitation(from_user: users(:one))
    member!(from_user).account.invitations.create!(
      email: "invitee@example.com",
      invited_by: from_user
    )
  end
end
