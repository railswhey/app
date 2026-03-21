# frozen_string_literal: true

puts "🌱 Seeding development data..."

# ── Demo user ────────────────────────────────────────────────────────────────
demo = User.find_by(email: "bob@email.com")

unless demo
  User::SignUpProcess.perform_now(
    email: "bob@email.com",
    username: "bob",
    password: "123123123",
    password_confirmation: "123123123"
  ) => [ :ok, demo ]
end

demo_person = Account::Person.find_by!(uuid: demo.uuid)
account = demo_person.accounts.first
workspace = ::Workspace.find_by!(uuid: account.uuid)
inbox = workspace.inbox

puts "  ✅ User: bob@email.com / 123123123 (username: bob)"

# ── Second user ──────────────────────────────────────────────────────────────
alice = User.find_by(email: "alice@email.com")

unless alice
  User::SignUpProcess.perform_now(
    email: "alice@email.com",
    username: "alice",
    password: "123123123",
    password_confirmation: "123123123"
  ) => [ :ok, alice ]
end

puts "  ✅ User: alice@email.com / 123123123 (username: alice)"

# ── Task List 1: Daily Essentials (title-only tasks) ─────────────────────────
daily = workspace.lists.find_or_create_by!(name: "Daily Essentials")

[
  "Restock ribeye steaks",
  "Buy 2 dozen eggs",
  "Pick up chicken thighs",
  "Refill spring water jugs",
  "Clean the espresso machine",
  "Check mailbox"
].each do |name|
  daily.tasks.find_or_create_by!(name:)
end

puts "  📋 Daily Essentials: #{daily.tasks.count} items"

# ── Task List 2: Relocation Logistics (title + description) ─────────────────
relocation = workspace.lists.find_or_create_by!(name: "Relocation Logistics")

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
  relocation.tasks.find_or_create_by!(name: attrs[:name]) do |item|
    item.description = attrs[:description]
  end
end

puts "  📋 Relocation Logistics: #{relocation.tasks.count} items"

# ── Task List 3: Software Launch (long titles + detailed descriptions) ───────
launch = workspace.lists.find_or_create_by!(name: "Software Launch")

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
  launch.tasks.find_or_create_by!(name: attrs[:name]) do |item|
    item.description = attrs[:description]
  end
end

puts "  📋 Software Launch: #{launch.tasks.count} items"

# ── Two empty task lists (for swapping/rebuilding) ───────────────────────────
empty_a = workspace.lists.find_or_create_by!(name: "Sandbox A")
empty_b = workspace.lists.find_or_create_by!(name: "Sandbox B")

puts "  📋 Sandbox A: empty"
puts "  📋 Sandbox B: empty"

# ── Some inbox items ─────────────────────────────────────────────────────────
[
  "Quick idea: dark mode toggle",
  "Follow up on API feedback",
  "Book dentist appointment"
].each do |name|
  inbox.tasks.find_or_create_by!(name:)
end

puts "  📥 Inbox: #{inbox.tasks.count} items"

# ── Alice's task list ─────────────────────────────────────────────────────────
alice_person = Account::Person.find_by!(uuid: alice.uuid)
alice_account = alice_person.accounts.first
alice_workspace = ::Workspace.find_by!(uuid: alice_account.uuid)
alice_inbox = alice_workspace.inbox

[ "Read chapter 5", "Reply to recruiter", "Grocery run" ].each do |name|
  alice_inbox.tasks.find_or_create_by!(name:)
end

alice_projects = alice_workspace.lists.find_or_create_by!(name: "Side Projects")
[ "Build portfolio site", "Write blog post about Rails 8", "Open-source CLI tool" ].each do |name|
  alice_projects.tasks.find_or_create_by!(name:)
end

puts "  📋 Alice's lists: Inbox (#{alice_inbox.tasks.count}), Side Projects (#{alice_projects.tasks.count})"

# ── Cross-user: transfer request (demo → alice) ─────────────────────────────
unless Workspace::List::Transfer.exists?(list: empty_a)
  transfer = Workspace::List::Transfer.create!(
    list: empty_a,
    from_workspace: workspace,
    to_workspace: alice_workspace,
    initiated_by: Workspace::Member.find_by!(uuid: demo.uuid)
  )

  User::Notification::Delivery.new(transfer).transfer_requested(to: alice)
  Workspace::ListTransferMailer.with(
    recipient_email: alice_account.owner.email,
    to_account_name: alice_account.name
  ).transfer_requested(transfer).deliver_later

  puts "  🔁 Transfer: demo offered 'Sandbox A' to alice (pending)"
end

# ── Cross-user: invitation (demo → alice) ────────────────────────────────────
unless account.invitations.exists?(email: alice.email)
  account.invitations.create!(email: alice.email, invited_by: demo_person)
  puts "  ✉️  Invitation: demo invited alice to join demo's workspace"
end

puts ""
puts "🚀 Seed complete!"
puts "   Login as demo:  bob@email.com  / 123123123"
puts "   Login as alice: alice@email.com / 123123123"
puts "   Lists: Inbox, Daily Essentials, Relocation Logistics, Software Launch, Sandbox A, Sandbox B"
puts "   Alice has 2 unread notifications (transfer + invitation)"
