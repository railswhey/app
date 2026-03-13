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
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def member!(user) = user

    def create_task_list(account, name:)
      account.task_lists.create!(name: name)
    end

    def create_task(user, name: "Foo", completed: false, task_list: member!(user).inbox)
      task = task_list.task_items.create!(name:)

      completed ? complete_task(task) : task
    end

    def complete_task(task)
      task.tap { _1.update_column(:completed_at, Time.current) }
    end

    def incomplete_task(task)
      task.tap { _1.update_column(:completed_at, nil) }
    end

    def create_comment(user, commentable, body: "A test comment")
      commentable.comments.create!(body:, user:)
    end

    def get_user_token(user)
      UserTokensForTesting[user]
    end
  end
end

class ActionDispatch::IntegrationTest
  class WebAdapter
    attr_reader :test

    def initialize(test)
      @test = test
    end

    def sign_in(user, password: "123123123")
      test.post(user__sessions_url, params: { user: { email: user.email, password: } })

      test.assert_redirected_to task__items_url(user.inbox)

      test.follow_redirect!
    end

    def assert_unauthorized_access
      test.assert_redirected_to new_user__session_url

      test.follow_redirect!

      test.assert_response :ok

      test.assert_select(".notice-text", "You need to sign in or sign up before continuing.")
    end

    def user__sessions_url = test.user_session_url
    def new_user__session_url = test.new_user_session_url

    def user__registrations_url = test.user_registrations_url
    def user__registration_url = test.user_registration_url
    def new_user__registration_url = test.new_user_registration_url

    def user__password_url(token = nil, **opts) = test.user_password_url(token:, **opts)
    def user__passwords_url = test.user_password_url
    def new_user__password_url = test.new_user_password_url
    def edit_user__password_url(token = nil, **opts) = test.edit_user_password_url(token:, **opts)

    def user__tokens_url = test.user_settings_token_url
    def edit_user__token_url = test.edit_user_settings_token_url

    def user__profiles_url = test.user_settings_profile_url
    def edit_user__profile_url = test.edit_user_settings_profile_url

    def task__list_url(...) = test.task_list_url(...)
    def task__lists_url = test.task_lists_url
    def new_task__list_url = test.new_task_list_url
    def edit_task__list_url(...) = test.edit_task_list_url(...)

    def task__item_url(...) = test.task_list_item_url(...)
    def task__items_url(...) = test.task_list_items_url(...)
    def new_task__item_url(...) = test.new_task_list_item_url(...)
    def edit_task__item_url(...) = test.edit_task_list_item_url(...)

    def complete_task__item_url(...) = test.task_list_item_complete_url(...)
    def incomplete_task__item_url(...) = test.task_list_item_incomplete_url(...)
    def move_task__item_url(task_list, task_item, **params)
      id = task_item.respond_to?(:id) ? task_item.id : task_item
      test.task_list_item_moves_url(task_list, task_item_id: id, **params)
    end

    def settings__url = test.user_settings_url
    def account__url = test.account_management_url
    def switch__account_url(account)
      id = account.respond_to?(:id) ? account.id : account
      test.account_switches_url(account_id: id)
    end

    def search__url = test.account_search_url
    def my__tasks_url = test.task_item_assignments_url
    def api__docs_url(...) = test.api_docs_url(...)
    def api__docs_raw_url = test.api_docs_url(format: :md)

    def account__invitations_url = test.account_invitations_url
    def new_account__invitation_url = test.new_account_invitation_url
    def account__invitation_url(...) = test.account_invitation_url(...)
    def show__invitation_url(token) = test.account_invitations_acceptance_url(token: token)
    def accept__invitation_url(token) = test.account_invitations_acceptance_url(token: token)

    def account__memberships_url = test.account_memberships_url
    def account__membership_url(...) = test.account_membership_url(...)

    def new_task__list_transfer_url(...) = test.new_task_list_transfer_url(...)
    def task__list_transfer_form_url(...) = test.task_list_transfer_url(...)
    def task__list_transfer_url(token, **kwargs) = test.account_transfers_response_url(token: token, **kwargs)
    def show_task__list_transfer_url(token, **kwargs) = test.account_transfers_response_url(token: token, **kwargs)
    def show_task__list_transfer_path(token, **kwargs) = test.account_transfers_response_path(token: token, **kwargs)

    def notifications__url(...) = test.user_notification_inbox_index_url(...)
    def notification__url(...) = test.user_notification_inbox_url(...)
    def mark_all_read__notifications_url = test.user_notification_reads_url

    # Comments on task lists
    def task_list__comments_url(task_list, ...) = test.task_list_comments_url(task_list, ...)
    def task_list__comment_url(task_list, comment, ...) = test.task_list_comment_url(task_list, comment, ...)
    def edit_task_list__comment_url(task_list, comment, ...) = test.edit_task_list_comment_url(task_list, comment, ...)

    # Comments on task items
    def task__item__comments_url(task_list, task_item, ...) = test.task_list_item_comments_url(task_list, task_item, ...)
    def task__item__comment_url(task_list, task_item, comment, ...) = test.task_list_item_comment_url(task_list, task_item, comment, ...)
    def edit_task__item__comment_url(task_list, task_item, comment, ...) = test.edit_task_list_item_comment_url(task_list, task_item, comment, ...)
  end

  class APIV1Adapter
    attr_reader :test

    def initialize(test)
      @test = test
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

    def user__sessions_url = test.user_session_url(format: :json)

    def user__registrations_url = test.user_registrations_url(format: :json)
    def user__registration_url = test.user_registration_url(format: :json)

    def user__passwords_url = test.user_password_url(format: :json)
    def user__password_url(token = nil, format: :json, **opts) = test.user_password_url(token:, format:, **opts)

    def user__tokens_url = test.user_settings_token_url(format: :json)

    def user__profiles_url = test.user_settings_profile_url(format: :json)

    def task__list_url(...) = test.task_list_url(...)
    def task__lists_url = test.task_lists_url(format: :json)

    def task__item_url(...) = test.task_list_item_url(...)
    def task__items_url(...) = test.task_list_items_url(...)
    def complete_task__item_url(...) = test.task_list_item_complete_url(...)
    def incomplete_task__item_url(...) = test.task_list_item_incomplete_url(...)

    def account__invitation_url(...) = test.account_invitation_url(...)
    def account__invitations_url(...) = test.account_invitations_url(...)
    def accept__invitation_url(token, format: :json) = test.account_invitations_acceptance_url(token: token, format: format)

    def account__membership_url(...) = test.account_membership_url(...)

    def new_task__list_transfer_url(...) = test.new_task_list_transfer_url(...)
    def task__list_transfer_form_url(...) = test.task_list_transfer_url(...)
    def task__list_transfer_url(token, **kwargs) = test.account_transfers_response_url(token: token, **kwargs)
    def show_task__list_transfer_url(token, **kwargs) = test.account_transfers_response_url(token: token, **kwargs)

    def my__tasks_url(**kwargs) = test.task_item_assignments_url(format: :json, **kwargs)
    def search__url(**kwargs) = test.account_search_url(format: :json, **kwargs)
  end

  def web_adapter
    WebAdapter.new(self)
  end

  def api_v1_adapter
    APIV1Adapter.new(self)
  end
end
