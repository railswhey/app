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

ActiveRecord::Schema[8.1].define(version: 2026_03_19_200001) do
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

  add_foreign_key "account_invitations", "account_people", column: "invited_by_id"
  add_foreign_key "account_invitations", "accounts"
  add_foreign_key "account_memberships", "account_people", column: "person_id"
  add_foreign_key "account_memberships", "accounts"
end
