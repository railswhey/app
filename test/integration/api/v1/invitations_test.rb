# frozen_string_literal: true

require "test_helper"

class APIV1InvitationsTest < ActionDispatch::IntegrationTest
  test "destroy responds with 404 when invitation not found" do
    user = users(:one)

    delete(
      api_v1_adapter.account__invitation_url(99_999_999, format: :json),
      headers: api_v1_adapter.authorization_header(user)
    )

    api_v1_adapter.assert_response_with_failure(:not_found)
  end

  test "create responds with 403 when user is not owner or admin" do
    collaborator = users(:two)
    # Downgrade user two's own membership to collaborator so the guard fires
    collaborator.accounts.first.memberships.find_by(user: collaborator).update!(role: :collaborator)

    post(
      api_v1_adapter.account__invitations_url(format: :json),
      params: { invitation: { email: "x@x.com" } },
      headers: api_v1_adapter.authorization_header(collaborator)
    )

    api_v1_adapter.assert_response_with_failure(:forbidden)
  end

  test "accept responds with error when accept fails" do
    inviter = users(:one)
    receiver = users(:two)
    member!(inviter)
    member!(receiver)
    invitation = inviter.account.invitations.create!(email: "fail@example.com", invited_by: inviter)

    # Lines 88-90 are only reachable when accept! returns false after the
    # accepted? guard passes (a race-condition scenario). No mock gem is
    # available in minitest 6, so we temporarily override the method.
    original = Invitation.instance_method(:accept!)
    Invitation.define_method(:accept!) { |_user| false }

    patch(
      api_v1_adapter.accept__invitation_url(invitation.token, format: :json),
      headers: api_v1_adapter.authorization_header(receiver)
    )

    api_v1_adapter.assert_response_with_failure(:unprocessable_entity)
  ensure
    Invitation.define_method(:accept!, original)
  end
end
