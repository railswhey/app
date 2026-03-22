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

ActiveRecord::Schema[8.1].define(version: 2026_03_21_000000) do
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

  add_foreign_key "user_notifications", "users"
  add_foreign_key "user_tokens", "users"
end
