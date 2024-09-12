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

ActiveRecord::Schema[7.2].define(version: 2024_09_11_235111) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "players", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_players_on_key"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "pods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "round_id"
    t.integer "number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "size", default: 4
    t.index ["number", "round_id"], name: "index_pods_on_number_and_round_id", unique: true
    t.index ["round_id"], name: "index_pods_on_round_id"
  end

  create_table "results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "round_id"
    t.uuid "tournament_participant_id"
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["round_id"], name: "index_results_on_round_id"
    t.index ["tournament_participant_id", "round_id"], name: "index_results_on_tournament_participant_id_and_round_id", unique: true
    t.index ["tournament_participant_id"], name: "index_results_on_tournament_participant_id"
  end

  create_table "rounds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tournament_id"
    t.integer "number", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "started_at"
    t.string "type", default: "SwissRound"
    t.datetime "finished_at"
    t.index ["tournament_id"], name: "index_rounds_on_tournament_id"
  end

  create_table "seatings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "pod_id"
    t.uuid "tournament_participant_id"
    t.integer "order", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pod_id"], name: "index_seatings_on_pod_id"
    t.index ["tournament_participant_id"], name: "index_seatings_on_tournament_participant_id"
  end

  create_table "tournament_organizers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tournament_organizers_on_user_id"
  end

  create_table "tournament_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tournament_id"
    t.uuid "player_id"
    t.string "decklist"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "dropped", default: false
    t.index ["player_id"], name: "index_tournament_participants_on_player_id"
    t.index ["tournament_id"], name: "index_tournament_participants_on_tournament_id"
  end

  create_table "tournaments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "state", default: 0, null: false
    t.integer "rounds_count", default: 0, null: false
    t.integer "tournament_participants_count", default: 0, null: false
    t.uuid "tournament_organizer_id"
    t.index ["tournament_organizer_id"], name: "index_tournaments_on_tournament_organizer_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "players", "users"
  add_foreign_key "pods", "rounds"
  add_foreign_key "results", "rounds"
  add_foreign_key "results", "tournament_participants"
  add_foreign_key "rounds", "tournaments"
  add_foreign_key "seatings", "pods"
  add_foreign_key "seatings", "tournament_participants"
  add_foreign_key "tournament_organizers", "users"
  add_foreign_key "tournament_participants", "players"
  add_foreign_key "tournament_participants", "tournaments"
end
