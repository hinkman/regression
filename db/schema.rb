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

ActiveRecord::Schema.define(version: 20141206001403) do

  create_table "actions", force: true do |t|
    t.string   "action"
    t.string   "item"
    t.integer  "item_id"
    t.integer  "user_id"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "actions", ["user_id"], name: "actions_user_id_fk", using: :btree

  create_table "config_files", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active"
    t.string   "cf_file_name"
    t.string   "cf_content_type"
    t.integer  "cf_file_size"
    t.datetime "cf_updated_at"
  end

  create_table "diffs", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active"
    t.integer  "config_file_id"
    t.integer  "left_id"
    t.integer  "right_id"
  end

  add_index "diffs", ["config_file_id"], name: "diffs_config_file_id_fk", using: :btree
  add_index "diffs", ["left_id"], name: "diffs_left_id_fk", using: :btree
  add_index "diffs", ["right_id"], name: "diffs_right_id_fk", using: :btree

  create_table "file_sets", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fs_file_name"
    t.string   "fs_content_type"
    t.integer  "fs_file_size"
    t.datetime "fs_updated_at"
  end

  create_table "results", force: true do |t|
    t.integer  "diff_id"
    t.text     "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active"
    t.integer  "pct_complete"
    t.integer  "left_count"
    t.integer  "right_count"
  end

  add_index "results", ["diff_id"], name: "results_diff_id_fk", using: :btree

  create_table "successful_files", force: true do |t|
    t.integer  "result_id"
    t.string   "left_name"
    t.string   "right_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "unmatched_files", force: true do |t|
    t.integer  "result_id"
    t.string   "side"
    t.string   "name"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unmatched_files", ["result_id"], name: "unmatched_files_result_id_fk", using: :btree

  create_table "unsuccessful_files", force: true do |t|
    t.integer  "result_id"
    t.integer  "left_line_number"
    t.text     "left_line"
    t.integer  "right_line_number"
    t.text     "right_line"
    t.string   "compare_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "useful"
  end

  create_table "users", force: true do |t|
    t.string   "login"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.datetime "last_login_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active"
    t.text     "cn_strings"
  end

  add_foreign_key "actions", "users", name: "actions_user_id_fk"

  add_foreign_key "diffs", "config_files", name: "diffs_config_file_id_fk"
  add_foreign_key "diffs", "file_sets", name: "diffs_left_id_fk", column: "left_id"
  add_foreign_key "diffs", "file_sets", name: "diffs_right_id_fk", column: "right_id"

  add_foreign_key "results", "diffs", name: "results_diff_id_fk"

  add_foreign_key "unmatched_files", "results", name: "unmatched_files_result_id_fk"

end
