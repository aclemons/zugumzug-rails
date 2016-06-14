# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160530224915) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cities", force: :cascade do |t|
    t.string   "name",                                 null: false
    t.decimal  "latitude",   precision: 18, scale: 12, null: false
    t.decimal  "longitude",  precision: 18, scale: 12, null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "cities", ["name"], name: "index_cities_on_name", unique: true, using: :btree

  create_table "destination_tickets", force: :cascade do |t|
    t.integer  "from_id",    null: false
    t.integer  "to_id",      null: false
    t.integer  "points",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_destination_tickets", force: :cascade do |t|
    t.integer  "game_id",                               null: false
    t.integer  "destination_ticket_id",                 null: false
    t.integer  "player_id"
    t.integer  "status",                                null: false
    t.integer  "deck_position",                         null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "completed",             default: false
  end

  create_table "game_routes", force: :cascade do |t|
    t.integer  "game_id",    null: false
    t.integer  "route_id",   null: false
    t.integer  "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_train_cards", force: :cascade do |t|
    t.integer  "game_id",       null: false
    t.integer  "train_card_id", null: false
    t.integer  "player_id"
    t.integer  "status",        null: false
    t.integer  "deck_position", null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "games", force: :cascade do |t|
    t.integer  "phase",             null: false
    t.integer  "turn_status",       null: false
    t.integer  "turn_player_id"
    t.integer  "last_player_id"
    t.integer  "winning_player_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "players", force: :cascade do |t|
    t.integer  "game_id",                 null: false
    t.integer  "user_id",                 null: false
    t.string   "name",                    null: false
    t.integer  "colour",                  null: false
    t.integer  "train_cars",              null: false
    t.integer  "position",                null: false
    t.integer  "points",                  null: false
    t.boolean  "longest_continuous_path", null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "players", ["game_id", "colour"], name: "index_players_on_game_id_and_colour", unique: true, using: :btree
  add_index "players", ["game_id", "name"], name: "index_players_on_game_id_and_name", unique: true, using: :btree
  add_index "players", ["game_id", "position"], name: "index_players_on_game_id_and_position", unique: true, using: :btree

  create_table "routes", force: :cascade do |t|
    t.integer  "from_id",    null: false
    t.integer  "to_id",      null: false
    t.integer  "colour",     null: false
    t.integer  "length",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "train_cards", force: :cascade do |t|
    t.integer  "colour",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",               null: false
    t.string   "email",              null: false
    t.string   "encrypted_password", null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["name"], name: "index_users_on_name", using: :btree

  add_foreign_key "destination_tickets", "cities", column: "from_id"
  add_foreign_key "destination_tickets", "cities", column: "to_id"
end
