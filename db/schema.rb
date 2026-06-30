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

ActiveRecord::Schema[8.0].define(version: 2026_06_26_194428) do
  create_table "account_direction_registry", force: :cascade do |t|
    t.integer "internal_code", null: false
    t.index ["internal_code"], name: "index_account_direction_registry_on_internal_code", unique: true
  end

  create_table "actor_profiles", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.string "display_name", null: false
    t.index ["actor_id"], name: "index_actor_profiles_on_actor_id"
  end

  create_table "actors", force: :cascade do |t|
  end

  create_table "bank_deposits", force: :cascade do |t|
    t.string "account_number", null: false
    t.date "opened_on", null: false
  end

  create_table "bonds", force: :cascade do |t|
    t.bigint "par_value_units", null: false
    t.date "maturity_date", null: false
    t.string "cusip_hex_id", limit: 72
  end

  create_table "checks", force: :cascade do |t|
    t.bigint "amount_units", null: false
    t.integer "check_number", null: false
  end

  create_table "day_count_conventions", force: :cascade do |t|
    t.string "label", limit: 50, null: false
    t.string "days_in_year_logic", limit: 20
    t.string "days_in_month_logic", limit: 20
  end

  create_table "financial_recordings", force: :cascade do |t|
    t.integer "instrument_type_id", null: false
    t.integer "liquidity_class_id", null: false
    t.integer "concrete_id", null: false
    t.datetime "created_at", null: false
    t.index ["instrument_type_id"], name: "index_financial_recordings_on_instrument_type_id"
    t.index ["liquidity_class_id"], name: "index_financial_recordings_on_liquidity_class_id"
  end

  create_table "instrument_registry", force: :cascade do |t|
    t.integer "internal_code", null: false
    t.index ["internal_code"], name: "index_instrument_registry_on_internal_code", unique: true
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.integer "recording_id", null: false
    t.integer "party_id", null: false
    t.integer "direction_id", null: false
    t.bigint "value_units", null: false
    t.index ["direction_id"], name: "index_ledger_entries_on_direction_id"
    t.index ["party_id"], name: "index_ledger_entries_on_party_id"
    t.index ["recording_id"], name: "index_ledger_entries_on_recording_id"
  end

  create_table "liquidity_class_registry", force: :cascade do |t|
    t.integer "internal_code", null: false
    t.index ["internal_code"], name: "index_liquidity_class_registry_on_internal_code", unique: true
  end

  create_table "promissory_notes", force: :cascade do |t|
    t.bigint "face_value_units", null: false
    t.date "issuance_date", null: false
    t.date "due_date"
  end

  add_foreign_key "actor_profiles", "actors"
  add_foreign_key "financial_recordings", "instrument_registry", column: "instrument_type_id"
  add_foreign_key "financial_recordings", "liquidity_class_registry", column: "liquidity_class_id"
  add_foreign_key "ledger_entries", "account_direction_registry", column: "direction_id"
  add_foreign_key "ledger_entries", "actors", column: "party_id"
  add_foreign_key "ledger_entries", "financial_recordings", column: "recording_id"
end
