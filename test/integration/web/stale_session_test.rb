# frozen_string_literal: true

require "test_helper"

class WebStaleSessionTest < ActionDispatch::IntegrationTest
  test "user recovers after being removed from another account" do
    # Setup: owner has an account, collaborator joins it
    owner = users(:one)
    owner_account = member!(owner).account

    collaborator = users(:two)
    member!(collaborator)
    collaborator_person = Account::Person.find_by!(uuid: collaborator.uuid)
    collab_membership = owner_account.memberships.create!(person: collaborator_person, role: :collaborator)

    # Collaborator signs in and switches to owner's account
    web_adapter.sign_in(collaborator)
    post web_adapter.switch__account_url(owner_account)

    # Verify collaborator is now on owner's account
    get web_adapter.task__lists_url
    assert_response :ok

    # Owner removes collaborator
    collab_membership.destroy!

    # Collaborator reloads — stale session should recover to their own account
    get web_adapter.task__lists_url
    assert_response :ok
  end

  test "user sees their own inbox after being removed from another account" do
    owner = users(:one)
    owner_account = member!(owner).account

    collaborator = users(:two)
    collaborator_inbox = member!(collaborator).inbox
    collaborator_person = Account::Person.find_by!(uuid: collaborator.uuid)
    collab_membership = owner_account.memberships.create!(person: collaborator_person, role: :collaborator)

    # Collaborator signs in and switches to owner's account
    web_adapter.sign_in(collaborator)
    post web_adapter.switch__account_url(owner_account)

    # Owner removes collaborator
    collab_membership.destroy!

    # Collaborator navigates to home — should land on their own inbox
    get web_adapter.task__lists_url
    assert_response :ok

    # Verify they can access their own account page
    get web_adapter.account__url
    assert_response :ok
  end

  test "user account page works after being removed from shared account" do
    owner = users(:one)
    owner_account = member!(owner).account

    collaborator = users(:two)
    member!(collaborator)
    collaborator_person = Account::Person.find_by!(uuid: collaborator.uuid)
    collab_membership = owner_account.memberships.create!(person: collaborator_person, role: :collaborator)

    # Collaborator signs in and switches to owner's account
    web_adapter.sign_in(collaborator)
    post web_adapter.switch__account_url(owner_account)

    # Owner removes collaborator
    collab_membership.destroy!

    # Collaborator visits account page — should recover and show their own account
    get web_adapter.account__url
    assert_response :ok
  end

  test "user can access settings after being removed from another account" do
    owner = users(:one)
    owner_account = member!(owner).account

    collaborator = users(:two)
    member!(collaborator)
    collaborator_person = Account::Person.find_by!(uuid: collaborator.uuid)
    collab_membership = owner_account.memberships.create!(person: collaborator_person, role: :collaborator)

    web_adapter.sign_in(collaborator)
    post web_adapter.switch__account_url(owner_account)

    collab_membership.destroy!

    get web_adapter.settings__url
    assert_response :ok
  end
end
