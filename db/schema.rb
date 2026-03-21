# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_19_200002) do
  create_table "account_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "invited_by_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_account_invitations_on_account_id_and_email", unique: true
    t.index ["account_id"], name: "index_account_invitations_on_account_id"
    t.index ["invited_by_id"], name: "index_account_invitations_on_invited_by_id"
    t.index ["token"], name: "index_account_invitations_on_token", unique: true
  end

  create_table "account_memberships", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "person_id", null: false
    t.string "role", limit: 16, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "person_id"], name: "index_account_memberships_on_account_id_and_person_id", unique: true
    t.index ["account_id"], name: "index_account_memberships_on_account_id"
    t.index ["person_id"], name: "index_account_memberships_on_person_id"
  end

  create_table "account_people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "uuid", null: false
    t.index ["uuid"], name: "index_account_people_on_uuid", unique: true
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.boolean "personal", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["uuid"], name: "index_accounts_on_uuid", unique: true
  end

  create_table "user_notifications", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.integer "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_user_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_user_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_user_notifications_on_user_id"
  end

  create_table "user_tokens", force: :cascade do |t|
    t.string "checksum", limit: 64, null: false
    t.datetime "created_at", null: false
    t.string "short", limit: 8, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["short"], name: "index_user_tokens_on_short", unique: true
    t.index ["user_id"], name: "index_user_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.string "uuid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  create_table "workspace_comments", force: :cascade do |t|
    t.text "body", null: false
    t.integer "commentable_id", null: false
    t.string "commentable_type", null: false
    t.datetime "created_at", null: false
    t.integer "member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id", "created_at"], name: "index_workspace_comments_on_commentable_and_created_at"
    t.index ["commentable_type", "commentable_id"], name: "index_workspace_comments_on_commentable"
    t.index ["member_id"], name: "index_workspace_comments_on_member_id"
  end

  create_table "workspace_list_transfers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "from_workspace_id", null: false
    t.integer "initiated_by_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "to_workspace_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "workspace_list_id", null: false
    t.index ["from_workspace_id"], name: "index_workspace_list_transfers_on_from_workspace_id"
    t.index ["initiated_by_id"], name: "index_workspace_list_transfers_on_initiated_by_id"
    t.index ["status"], name: "index_workspace_list_transfers_on_status"
    t.index ["to_workspace_id"], name: "index_workspace_list_transfers_on_to_workspace_id"
    t.index ["token"], name: "index_workspace_list_transfers_on_token", unique: true
    t.index ["workspace_list_id"], name: "index_workspace_list_transfers_on_workspace_list_id"
  end

  create_table "workspace_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "inbox", default: false, null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "workspace_id", null: false
    t.index ["workspace_id"], name: "index_workspace_lists_inbox", unique: true, where: "inbox"
    t.index ["workspace_id"], name: "index_workspace_lists_on_workspace_id"
  end

  create_table "workspace_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "role", limit: 16
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "uuid", null: false
    t.integer "workspace_id"
    t.index ["uuid"], name: "index_workspace_members_on_uuid", unique: true
    t.index ["workspace_id"], name: "index_workspace_members_on_workspace_id"
  end

  create_table "workspace_tasks", force: :cascade do |t|
    t.integer "assigned_member_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "workspace_list_id", null: false
    t.index ["assigned_member_id"], name: "index_workspace_tasks_on_assigned_member_id"
    t.index ["completed_at"], name: "index_workspace_tasks_on_completed_at"
    t.index ["workspace_list_id"], name: "index_workspace_tasks_on_workspace_list_id"
  end

  create_table "workspaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["uuid"], name: "index_workspaces_on_uuid", unique: true
  end

  add_foreign_key "account_invitations", "account_people", column: "invited_by_id"
  add_foreign_key "account_invitations", "accounts"
  add_foreign_key "account_memberships", "account_people", column: "person_id"
  add_foreign_key "account_memberships", "accounts"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "user_tokens", "users"
  add_foreign_key "workspace_comments", "workspace_members", column: "member_id"
  add_foreign_key "workspace_list_transfers", "workspace_lists"
  add_foreign_key "workspace_list_transfers", "workspace_members", column: "initiated_by_id"
  add_foreign_key "workspace_list_transfers", "workspaces", column: "from_workspace_id"
  add_foreign_key "workspace_list_transfers", "workspaces", column: "to_workspace_id"
  add_foreign_key "workspace_lists", "workspaces"
  add_foreign_key "workspace_members", "workspaces"
  add_foreign_key "workspace_tasks", "workspace_lists"
  add_foreign_key "workspace_tasks", "workspace_members", column: "assigned_member_id"
end
