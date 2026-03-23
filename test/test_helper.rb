# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/lib/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module UserTokensForTesting
  OPTIONS = {
    "one" => "Bh3ok8BL_XTNYFvwaRATjSoS3o5zjeQ4gWpQuUjd3",
    "two" => "dSNZRXsU_QAB7obbYzBZ9NPwD3suoQNxiSP8N2zPn"
  }.freeze

  def self.[](user)
    OPTIONS.fetch(user.email.split("@").first)
  end
end

class MemberContext < SimpleDelegator
  def account
    @account ||= begin
      membership = person.memberships.find_by(role: Account::Membership::OWNER) || person.memberships.first
      membership&.account
    end
  end

  def person
    @person ||= Account::Person.find_by!(uuid: uuid)
  end

  def workspace
    @workspace ||= ::Workspace.find_by!(uuid: account.uuid)
  end

  def inbox
    workspace.inbox
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do |worker|
      SimpleCov.result
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    set_fixture_class workspaces: Workspace,
                      workspace_members: Workspace::Member,
                      workspace_lists: Workspace::List,
                      workspace_tasks: Workspace::Task,
                      workspace_comments: Workspace::Comment,
                      workspace_list_transfers: Workspace::List::Transfer,
                      user_tokens: User::Token,
                      user_notifications: User::Notification,
                      account_invitations: Account::Invitation,
                      account_memberships: Account::Membership,
                      account_people: Account::Person

    fixtures :all

    # Add more helper methods to be used by all tests here...
    # Semantic marker — wraps a User with workspace-level accessors.
    # See Constitution: "member! is the single point where complexity gets absorbed."
    def member!(user)
      MemberContext.new(user)
    end

    def create_task_list(account, name:)
      workspace = ::Workspace.find_by!(uuid: account.uuid)
      workspace.lists.create!(name: name)
    end

    def create_task(user, name: "Foo", completed: false, task_list: member!(user).inbox)
      task = task_list.tasks.create!(name:)

      completed ? complete_task(task) : task
    end

    def complete_task(task)
      task.tap { it.update_column(:completed_at, Time.current) }
    end

    def incomplete_task(task)
      task.tap { it.update_column(:completed_at, nil) }
    end

    def create_comment(user, commentable, body: "A test comment")
      member = Workspace::Member.find_by!(uuid: user.uuid)
      commentable.comments.create!(body:, member:)
    end

    def get_user_token(user)
      UserTokensForTesting[user]
    end
  end
end

class ActionDispatch::IntegrationTest
  class WebAdapter
    include Web::Engine.routes.url_helpers

    attr_reader :test

    def initialize(test)
      @test = test
    end

    def default_url_options
      { host: "www.example.com" }
    end

    def sign_in(user, password: "123123123")
      test.post(user__sessions_url, params: { user: { email: user.email, password: } })

      test.assert_redirected_to task__items_url(test.member!(user).inbox)

      test.follow_redirect!
    end

    def assert_unauthorized_access
      test.assert_redirected_to new_user__session_url

      test.follow_redirect!

      test.assert_response :ok

      test.assert_select(".notice-text", "You need to sign in or sign up before continuing.")
    end

    def user__sessions_url = user_session_url
    def new_user__session_url = new_user_session_url

    def user__registrations_url = user_registrations_url
    def user__registration_url = user_registration_url
    def new_user__registration_url = new_user_registration_url

    def user__password_url(token = nil, **opts) = user_password_url(token:, **opts)
    def user__passwords_url = user_password_url
    def new_user__password_url = new_user_password_url
    def edit_user__password_url(token = nil, **opts) = edit_user_password_url(token:, **opts)

    def user__tokens_url = user_settings_token_url
    def edit_user__token_url = edit_user_settings_token_url

    def user__profiles_url = user_settings_profile_url
    def edit_user__profile_url = edit_user_settings_profile_url
    def user__settings_password_url = user_settings_password_url

    def task__list_url(...) = task_list_url(...)
    def task__lists_url = task_lists_url
    def new_task__list_url = new_task_list_url
    def edit_task__list_url(...) = edit_task_list_url(...)

    def task__item_url(...) = task_list_item_url(...)
    def task__items_url(...) = task_list_items_url(...)
    def new_task__item_url(...) = new_task_list_item_url(...)
    def edit_task__item_url(...) = edit_task_list_item_url(...)

    def complete_task__item_url(...) = task_list_item_complete_url(...)
    def incomplete_task__item_url(...) = task_list_item_incomplete_url(...)
    def move_task__item_url(task_list, task_item, **params)
      id = task_item.respond_to?(:id) ? task_item.id : task_item
      task_list_item_moves_url(task_list, task_item_id: id, **params)
    end

    def settings__url = user_settings_url
    def account__url = account_management_url
    def switch__account_url(account)
      id = account.respond_to?(:id) ? account.id : account
      account_switches_url(account_id: id)
    end

    def search__url = account_search_url
    def my__tasks_url = task_item_assignments_url
    def api__docs_url(...) = api_docs_url(...)
    def api__docs_raw_url = api_docs_url(format: :md)

    def account__invitations_url = account_invitations_url
    def new_account__invitation_url = new_account_invitation_url
    def account__invitation_url(...) = account_invitation_url(...)
    def show__invitation_url(token) = account_invitations_acceptance_url(token: token)
    def accept__invitation_url(token) = account_invitations_acceptance_url(token: token)

    def account__memberships_url = account_memberships_url
    def account__membership_url(...) = account_membership_url(...)

    def new_task__list_transfer_url(...) = new_task_list_transfer_url(...)
    def task__list_transfer_form_url(...) = task_list_transfer_url(...)
    def task__list_transfer_url(token, **kwargs) = account_transfers_response_url(token: token, **kwargs)
    def show_task__list_transfer_url(token, **kwargs) = account_transfers_response_url(token: token, **kwargs)
    def show_task__list_transfer_path(token, **kwargs) = account_transfers_response_path(token: token, **kwargs)

    def notifications__url(...) = user_notification_inbox_index_url(...)
    def notification__url(...) = user_notification_inbox_url(...)
    def mark_all_read__notifications_url = user_notification_reads_url

    # Comments on task lists
    def task_list__comments_url(task_list, ...) = task_list_comments_url(task_list, ...)
    def task_list__comment_url(task_list, comment, ...) = task_list_comment_url(task_list, comment, ...)
    def edit_task_list__comment_url(task_list, comment, ...) = edit_task_list_comment_url(task_list, comment, ...)

    # Comments on task items
    def task__item__comments_url(task_list, task_item, ...) = task_list_item_comments_url(task_list, task_item, ...)
    def task__item__comment_url(task_list, task_item, comment, ...) = task_list_item_comment_url(task_list, task_item, comment, ...)
    def edit_task__item__comment_url(task_list, task_item, comment, ...) = edit_task_list_item_comment_url(task_list, task_item, comment, ...)
  end

  class APIV1Adapter
    include API::Engine.routes.url_helpers

    attr_reader :test

    def initialize(test)
      @test = test
    end

    def default_url_options
      { host: "www.example.com" }
    end

    def authorization_header(arg)
      user_token = arg.is_a?(User) ? UserTokensForTesting[arg] : arg

      { "Authorization" => "Bearer #{user_token}" }
    end

    def assert_response_with_failure(status)
      test.assert_response(status)

      json_response = test.response.parsed_body.with_indifferent_access

      test.assert_equal "failure", json_response["status"]
      test.assert_equal "object", json_response["type"]

      json_data = json_response["data"]

      test.assert_kind_of Hash, json_data
      test.assert_kind_of String, json_data["message"]
      test.assert_kind_of Hash, json_data["details"]

      json_data
    end

    def assert_response_with_success(status)
      test.assert_response(status)

      json_response = test.response.parsed_body.with_indifferent_access

      test.assert_equal "success", json_response["status"]

      json_data = json_response["data"]

      case json_response["type"]
      when "object" then test.assert_kind_of(Hash, json_data)
      when "array" then test.assert_kind_of(Array, json_data)
      else test.flunk("Unexpected type: #{json_response["type"].inspect}. Expected \"object\" or \"collection\".")
      end

      json_data
    end

    def user__sessions_url = v1_user_session_url

    def user__registrations_url = v1_user_registrations_url
    def user__registration_url = v1_user_registration_url

    def user__passwords_url = v1_user_password_url
    def user__password_url(token = nil, **opts) = v1_user_password_url(token:, **opts)

    def user__tokens_url = v1_user_settings_token_url

    def user__profiles_url = v1_user_settings_profile_url
    def user__settings_password_url = v1_user_settings_password_url

    def task__list_url(...) = v1_task_list_url(...)
    def task__lists_url = v1_task_lists_url

    def task__item_url(...) = v1_task_list_item_url(...)
    def task__items_url(...) = v1_task_list_items_url(...)
    def complete_task__item_url(...) = v1_task_list_item_complete_url(...)
    def incomplete_task__item_url(...) = v1_task_list_item_incomplete_url(...)

    def account__invitation_url(...) = v1_account_invitation_url(...)
    def account__invitations_url(...) = v1_account_invitations_url(...)
    def accept__invitation_url(token, **) = v1_account_invitations_acceptance_url(token: token)

    def account__membership_url(...) = v1_account_membership_url(...)

    def new_task__list_transfer_url(list_id, **) = v1_task_list_url(list_id)
    def task__list_transfer_form_url(...) = v1_task_list_transfer_url(...)
    def task__list_transfer_url(token, **kwargs) = v1_account_transfers_response_url(token: token, **kwargs)
    def show_task__list_transfer_url(token, **kwargs) = v1_account_transfers_response_url(token: token, **kwargs)

    def my__tasks_url(**kwargs) = v1_task_item_assignments_url(**kwargs)
    def search__url(**kwargs) = v1_account_search_url(**kwargs)
  end

  def web_adapter
    WebAdapter.new(self)
  end

  def api_v1_adapter
    APIV1Adapter.new(self)
  end
end
