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

ActiveRecord::Schema[8.1].define(version: 2026_03_03_140725) do
  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.boolean "personal", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["uuid"], name: "index_accounts_on_uuid", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.integer "commentable_id", null: false
    t.string "commentable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["commentable_type", "commentable_id", "created_at"], name: "index_comments_on_commentable_and_created_at"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "invited_by_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_invitations_on_account_id_and_email", unique: true
    t.index ["account_id"], name: "index_invitations_on_account_id"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role", limit: 16, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id", "user_id"], name: "index_memberships_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_memberships_on_account_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.integer "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "task_items", force: :cascade do |t|
    t.integer "assigned_user_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "task_list_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_task_items_on_assigned_user_id"
    t.index ["completed_at"], name: "index_task_items_on_completed_at"
    t.index ["task_list_id"], name: "index_task_items_on_task_list_id"
  end

  create_table "task_list_transfers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "from_account_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "task_list_id", null: false
    t.integer "to_account_id", null: false
    t.string "token", null: false
    t.integer "transferred_by_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_account_id"], name: "index_task_list_transfers_on_from_account_id"
    t.index ["status"], name: "index_task_list_transfers_on_status"
    t.index ["task_list_id"], name: "index_task_list_transfers_on_task_list_id"
    t.index ["to_account_id"], name: "index_task_list_transfers_on_to_account_id"
    t.index ["token"], name: "index_task_list_transfers_on_token", unique: true
    t.index ["transferred_by_id"], name: "index_task_list_transfers_on_transferred_by_id"
  end

  create_table "task_lists", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "inbox", default: false, null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_task_lists_inbox", unique: true, where: "inbox"
    t.index ["account_id"], name: "index_task_lists_on_account_id"
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "comments", "users"
  add_foreign_key "invitations", "accounts"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "memberships", "accounts"
  add_foreign_key "memberships", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "task_items", "task_lists"
  add_foreign_key "task_items", "users", column: "assigned_user_id"
  add_foreign_key "task_list_transfers", "accounts", column: "from_account_id"
  add_foreign_key "task_list_transfers", "accounts", column: "to_account_id"
  add_foreign_key "task_list_transfers", "task_lists"
  add_foreign_key "task_list_transfers", "users", column: "transferred_by_id"
  add_foreign_key "task_lists", "accounts"
  add_foreign_key "user_tokens", "users"
end
