# frozen_string_literal: true

require "test_helper"

class WebApiDocsTest < ActionDispatch::IntegrationTest
  # ── routing / status ──────────────────────────────────────────────────────

  test "shows default (index) section when no section param given" do
    get web_adapter.api__docs_url
    assert_response :ok
  end

  test "shows a valid section" do
    get web_adapter.api__docs_url(section: "task_items")
    assert_response :ok
  end

  test "falls back to index when section is invalid" do
    get web_adapter.api__docs_url(section: "does_not_exist")
    assert_response :ok
  end

  test "shows each known section without error" do
    Web::APIDocsController::SECTIONS.each do |section|
      get web_adapter.api__docs_url(section:)
      assert_response :ok, "expected 200 for section=#{section}"
    end
  end

  # ── :md template handler ──────────────────────────────────────────────────

  test ":md template handler is registered with ActionView" do
    handler = ActionView::Template.send(:handler_for_extension, "md")
    assert_equal MarkdownHandler, handler,
      "MarkdownHandler must be registered for .md templates (survives code reloads via to_prepare)"
  end

  # ── markdown → HTML rendering ─────────────────────────────────────────────

  test "markdown headings are rendered as HTML h1/h2 elements" do
    get web_adapter.api__docs_url
    assert_select "h1", minimum: 1
    assert_select "h2", minimum: 1
  end

  test "fenced code blocks are rendered as HTML pre/code elements" do
    get web_adapter.api__docs_url(section: "task_lists")
    assert_select "pre code", minimum: 1
  end

  # ── ERB interpolation ─────────────────────────────────────────────────────

  test "ERB tags are not present in rendered HTML" do
    Web::APIDocsController::SECTIONS.each do |section|
      get web_adapter.api__docs_url(section:)
      assert_no_match(/&lt;%=|<%=/, response.body,
        "raw ERB tag found in section=#{section} — interpolation failed")
    end
  end

  test "base_url ERB expression is resolved in rendered HTML" do
    get web_adapter.api__docs_url(section: "task_lists")
    assert_includes response.body, "http://www.example.com",
      "request.base_url should be expanded in rendered output"
  end

  # ── section-specific content ──────────────────────────────────────────────

  test "index section renders the API overview heading" do
    get web_adapter.api__docs_url
    assert_select "h1", text: /Rails Whey App API/i
  end

  test "index section does not contain 'not yet available' notice" do
    get web_adapter.api__docs_url
    assert_no_match(/not yet available/i, response.body)
    assert_no_match(/406/i, response.body)
  end

  test "my_tasks section renders the My Tasks heading and curl example" do
    get web_adapter.api__docs_url(section: "my_tasks")
    assert_select "h1", text: /My Tasks/i
    assert_select "pre code", text: /task\/item\/assignments\.json/
  end

  test "my_tasks section does not contain JSON-not-supported notice" do
    get web_adapter.api__docs_url(section: "my_tasks")
    assert_no_match(/not yet supported/i, response.body)
    assert_no_match(/406/i, response.body)
  end

  test "search section renders the Search heading and curl example" do
    get web_adapter.api__docs_url(section: "search")
    assert_select "h1", text: /Search/i
    assert_select "pre code", text: /search\.json/
  end

  test "search section does not contain JSON-not-supported notice" do
    get web_adapter.api__docs_url(section: "search")
    assert_no_match(/not yet supported/i, response.body)
    assert_no_match(/406/i, response.body)
  end

  test "task_lists section renders all CRUD headings" do
    get web_adapter.api__docs_url(section: "task_lists")
    assert_select "h2", text: /List all task lists/i
    assert_select "h2", text: /Create a task list/i
    assert_select "h2", text: /Update a task list/i
    assert_select "h2", text: /Delete a task list/i
  end

  test "task_items section renders all action headings" do
    get web_adapter.api__docs_url(section: "task_items")
    assert_select "h2", text: /List items/i
    assert_select "h2", text: /Create a task item/i
    assert_select "h2", text: /Mark complete/i
    assert_select "h2", text: /Mark incomplete/i
    assert_select "h2", text: /Move to another list/i
  end

  # ── nav / layout ──────────────────────────────────────────────────────────

  test "layout renders nav links for all sections" do
    get web_adapter.api__docs_url
    Web::APIDocsController::SECTIONS.each do |section|
      assert_select "a[href*='#{section}']", minimum: 1,
        message: "expected a nav link for section=#{section}"
    end
  end

  test "layout contains link to raw markdown" do
    get web_adapter.api__docs_url
    assert_select "a[href$='.md']", minimum: 1
  end

  # ── raw markdown endpoint ─────────────────────────────────────────────────

  test "raw endpoint returns text/markdown content type" do
    get web_adapter.api__docs_raw_url
    assert_response :ok
    assert_equal "text/markdown", response.media_type
  end

  test "raw endpoint contains all section headings" do
    get web_adapter.api__docs_raw_url
    assert_includes response.body, "# Index"
    assert_includes response.body, "# My Tasks"
    assert_includes response.body, "# Search"
    assert_includes response.body, "# Task Lists"
    assert_includes response.body, "# Task Items"
  end

  test "raw endpoint resolves ERB and does not contain literal ERB tags" do
    get web_adapter.api__docs_raw_url
    assert_no_match(/<%=/, response.body,
      "raw markdown output should not contain unresolved ERB tags")
  end

  test "raw endpoint resolves base_url in output" do
    get web_adapter.api__docs_raw_url
    assert_includes response.body, "http://www.example.com"
  end
end
