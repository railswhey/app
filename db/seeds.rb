# frozen_string_literal: true

puts "🌱 Seeding development data..."

# ── Demo user ────────────────────────────────────────────────────────────────
demo = User.find_or_initialize_by(email: "bob@email.com")
demo.username = "bob"
demo.password = "123123123"
demo.password_confirmation = "123123123"
demo.save!

account = demo.account
inbox = account.inbox

puts "  ✅ User: bob@email.com / 123123123 (username: bob)"

# ── Second user ──────────────────────────────────────────────────────────────
alice = User.find_or_initialize_by(email: "alice@email.com")
alice.username = "alice"
alice.password = "123123123"
alice.password_confirmation = "123123123"
alice.save!

puts "  ✅ User: alice@email.com / 123123123 (username: alice)"

# ── Task List 1: Daily Essentials (title-only tasks) ─────────────────────────
daily = account.task_lists.find_or_create_by!(name: "Daily Essentials")

[
  "Restock ribeye steaks",
  "Buy 2 dozen eggs",
  "Pick up chicken thighs",
  "Refill spring water jugs",
  "Clean the espresso machine",
  "Check mailbox"
].each do |name|
  daily.task_items.find_or_create_by!(name:)
end

puts "  📋 Daily Essentials: #{daily.task_items.count} items"

# ── Task List 2: Relocation Logistics (title + description) ─────────────────
relocation = account.task_lists.find_or_create_by!(name: "Relocation Logistics")

[
  {
    name: "Research Property Taxes",
    description: "Compare the annual rates between Travis County and Orange County."
  },
  {
    name: "Update EB-1 Folder",
    description: "Upload the latest professional certifications to the cloud drive."
  },
  {
    name: "School Enrollment Inquiry",
    description: "Email local bilingual programs regarding mid-year placement for three students."
  },
  {
    name: "Contact Moving Coordinator",
    description: "Get a quote for international shipping and container sizes."
  },
  {
    name: "Verify Health Insurance",
    description: "Check which providers offer the best coverage for a family of five in Texas."
  }
].each do |attrs|
  relocation.task_items.find_or_create_by!(name: attrs[:name]) do |item|
    item.description = attrs[:description]
  end
end

puts "  📋 Relocation Logistics: #{relocation.task_items.count} items"

# ── Task List 3: Software Launch (long titles + detailed descriptions) ───────
launch = account.task_lists.find_or_create_by!(name: "Software Launch")

[
  {
    name: "Implement Robust OAuth2 Authentication Flow with Refresh Token Logic",
    description: "The system currently lacks a secure way to persist sessions. We need to integrate a provider that supports JWT, handle token expiration gracefully, and ensure the redirect URIs are properly configured for both development and production environments."
  },
  {
    name: "Refactor Database Schema to Support Multi-Tenant Architecture and Data Isolation",
    description: "As we scale, we need to ensure that each user's data is logically separated. This involves adding a tenant_id to every table, updating all existing queries to filter by this ID, and running a migration script that doesn't cause downtime for current active users."
  },
  {
    name: "Design and Conduct Comprehensive End-to-End Testing Suite for Core API Endpoints",
    description: "We need to simulate real-world user behavior by chaining requests: creating a user, authenticating, posting data, and deleting the account. The tests should run in a headless browser environment and generate a detailed HTML report for the CI/CD pipeline."
  },
  {
    name: "Optimize Front-End Asset Delivery Using Global Content Delivery Network (CDN)",
    description: "The initial page load is currently exceeding 3 seconds. We need to minify all CSS/JS files, implement lazy loading for images, and configure the edge servers to cache static assets closer to the end-users to reduce latency globally."
  }
].each do |attrs|
  launch.task_items.find_or_create_by!(name: attrs[:name]) do |item|
    item.description = attrs[:description]
  end
end

puts "  📋 Software Launch: #{launch.task_items.count} items"

# ── Two empty task lists (for swapping/rebuilding) ───────────────────────────
empty_a = account.task_lists.find_or_create_by!(name: "Sandbox A")
empty_b = account.task_lists.find_or_create_by!(name: "Sandbox B")

puts "  📋 Sandbox A: empty"
puts "  📋 Sandbox B: empty"

# ── Some inbox items ─────────────────────────────────────────────────────────
[
  "Quick idea: dark mode toggle",
  "Follow up on API feedback",
  "Book dentist appointment"
].each do |name|
  inbox.task_items.find_or_create_by!(name:)
end

puts "  📥 Inbox: #{inbox.task_items.count} items"

# ── Alice's task list ─────────────────────────────────────────────────────────
alice_account = alice.account
alice_inbox = alice_account.inbox

[ "Read chapter 5", "Reply to recruiter", "Grocery run" ].each do |name|
  alice_inbox.task_items.find_or_create_by!(name:)
end

alice_projects = alice_account.task_lists.find_or_create_by!(name: "Side Projects")
[ "Build portfolio site", "Write blog post about Rails 8", "Open-source CLI tool" ].each do |name|
  alice_projects.task_items.find_or_create_by!(name:)
end

puts "  📋 Alice's lists: Inbox (#{alice_inbox.task_items.count}), Side Projects (#{alice_projects.task_items.count})"

# ── Cross-user: transfer request (demo → alice) ─────────────────────────────
unless Task::List::Transfer.exists?(task_list: empty_a)
  Task::List::Transfer.create!(
    task_list: empty_a,
    from_account: account,
    to_account: alice_account,
    transferred_by: demo,
    to_user: alice
  )
  puts "  🔁 Transfer: demo offered 'Sandbox A' to alice (pending)"
end

# ── Cross-user: invitation (demo → alice) ────────────────────────────────────
unless account.invitations.exists?(email: alice.email)
  account.invitations.create!(email: alice.email, invited_by: demo)
  puts "  ✉️  Invitation: demo invited alice to join demo's workspace"
end

puts ""
puts "🚀 Seed complete!"
puts "   Login as demo:  bob@email.com  / 123123123"
puts "   Login as alice: alice@email.com / 123123123"
puts "   Lists: Inbox, Daily Essentials, Relocation Logistics, Software Launch, Sandbox A, Sandbox B"
puts "   Alice has 2 unread notifications (transfer + invitation)"
