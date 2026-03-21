# frozen_string_literal: true

require "test_helper"

class WebMyTasksTest < ActionDispatch::IntegrationTest
  test "guest cannot access my tasks" do
    get web_adapter.my__tasks_url
    web_adapter.assert_unauthorized_access
  end

  test "user accesses my tasks page" do
    user = users(:one)
    member!(user)
    web_adapter.sign_in(user)

    get web_adapter.my__tasks_url
    assert_response :ok
  end

  test "user sees assigned tasks" do
    user = users(:one)
    member!(user)
    task = create_task(user, name: "Assigned to me")
    task.update!(assigned_member: Workspace::Member.find_by!(uuid: user.uuid))
    web_adapter.sign_in(user)

    get web_adapter.my__tasks_url
    assert_response :ok
    assert_select "a", /Assigned to me/
  end

  test "user filters my tasks by completed" do
    user = users(:one)
    member!(user)
    task = create_task(user, name: "Done task", completed: true)
    task.update!(assigned_member: Workspace::Member.find_by!(uuid: user.uuid))
    web_adapter.sign_in(user)

    get web_adapter.my__tasks_url, params: { filter: "completed" }
    assert_response :ok
  end

  test "user filters my tasks by incomplete" do
    user = users(:one)
    member!(user)
    task = create_task(user, name: "Pending task")
    task.update!(assigned_member: Workspace::Member.find_by!(uuid: user.uuid))
    web_adapter.sign_in(user)

    get web_adapter.my__tasks_url, params: { filter: "incomplete" }
    assert_response :ok
  end
end
