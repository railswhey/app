# frozen_string_literal: true

require "test_helper"

class WebErrorsTest < ActionDispatch::IntegrationTest
  test "404 page renders for unauthenticated user" do
    get "/404"

    assert_response :not_found
    assert_select "h2", "Page not found"
    assert_select "a", /Sign in/
  end

  test "404 page renders for authenticated user with navigation" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get "/404"

    assert_response :not_found
    assert_select "h2", "Page not found"
    assert_select "a", /Back to My Lists/
  end

  test "422 page renders for unauthenticated user" do
    get "/422"

    assert_response :unprocessable_entity
    assert_select "h2", "Request not accepted"
    assert_select "a", /Start over/
  end

  test "422 page renders for authenticated user" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get "/422"

    assert_response :unprocessable_entity
    assert_select "h2", "Request not accepted"
    assert_select "a", /Back to My Lists/
  end

  test "500 page renders" do
    get "/500"

    assert_response :internal_server_error
    assert_select "h2", "Something went wrong"
    assert_select "a", /Go to Home/
  end
end
