# frozen_string_literal: true

require "test_helper"

class WebMembershipsTest < ActionDispatch::IntegrationTest
  test "guest cannot list memberships" do
    get web_adapter.account__memberships_url
    web_adapter.assert_unauthorized_access
  end

  test "owner lists memberships" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.account__memberships_url
    assert_response :ok
  end

  test "owner cannot remove themselves" do
    user = users(:one)
    user_person = Account::Person.find_by!(uuid: user.uuid)
    membership = member!(user).account.memberships.find_by(person: user_person)
    web_adapter.sign_in(user)

    delete web_adapter.account__membership_url(membership)
    assert_redirected_to web_adapter.account__url
  end

  test "owner cannot remove another owner" do
    owner = users(:one)
    account = member!(owner).account

    other = users(:two)
    member!(other)
    other_person = Account::Person.find_by!(uuid: other.uuid)
    collab = account.memberships.create!(person: other_person, role: :collaborator)

    web_adapter.sign_in(owner)

    delete web_adapter.account__membership_url(collab)
    assert_redirected_to web_adapter.account__url
    follow_redirect!
    assert_select ".notice-text", /Member removed/
  end

  test "owner removes a collaborator" do
    owner = users(:one)
    account = member!(owner).account
    other = users(:two)
    other_person = Account::Person.find_by!(uuid: other.uuid)
    collab = account.memberships.create!(person: other_person, role: :collaborator)

    web_adapter.sign_in(owner)

    assert_difference "account.memberships.count", -1 do
      delete web_adapter.account__membership_url(collab)
    end
    assert_redirected_to web_adapter.account__url
  end

  test "collaborator cannot remove a member" do
    owner = users(:one)
    account = member!(owner).account
    collaborator = users(:two)
    member!(collaborator)
    collaborator_person = Account::Person.find_by!(uuid: collaborator.uuid)
    collab_membership = account.memberships.create!(person: collaborator_person, role: :collaborator)

    web_adapter.sign_in(collaborator)
    # Switch to the shared account so Current.account resolves correctly
    post web_adapter.switch__account_url(account)

    delete web_adapter.account__membership_url(collab_membership)
    assert_redirected_to web_adapter.account__url
    follow_redirect!
    assert_select ".notice-text", /Only owners and admins/
  end

  test "admin cannot remove themselves" do
    owner = users(:one)
    account = member!(owner).account
    admin = users(:two)
    member!(admin)
    admin_person = Account::Person.find_by!(uuid: admin.uuid)
    admin_membership = account.memberships.create!(person: admin_person, role: :admin)

    web_adapter.sign_in(admin)
    # Switch to the shared account so Current.account resolves correctly
    post web_adapter.switch__account_url(account)

    delete web_adapter.account__membership_url(admin_membership)
    assert_redirected_to web_adapter.account__url
    follow_redirect!
    assert_select ".notice-text", /Cannot remove yourself/
  end
end
