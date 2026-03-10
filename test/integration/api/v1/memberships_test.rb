# frozen_string_literal: true

require "test_helper"

class APIV1MembershipsTest < ActionDispatch::IntegrationTest
  test "destroy responds with 404 when membership not found" do
    user = users(:one)

    delete(
      api_v1_adapter.account__membership_url(99_999_999, format: :json),
      headers: api_v1_adapter.authorization_header(user)
    )

    api_v1_adapter.assert_response_with_failure(:not_found)
  end
end
