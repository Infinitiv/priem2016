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

ActiveRecord::Schema.define(version: 20160607080100) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admission_volumes", force: :cascade do |t|
    t.integer  "campaign_id"
    t.integer  "education_level_id"
    t.integer  "direction_id"
    t.integer  "number_budget_o",    default: 0
    t.integer  "number_budget_oz",   default: 0
    t.integer  "number_budget_z",    default: 0
    t.integer  "number_paid_o",      default: 0
    t.integer  "number_paid_oz",     default: 0
    t.integer  "number_paid_z",      default: 0
    t.integer  "number_target_o",    default: 0
    t.integer  "number_target_oz",   default: 0
    t.integer  "number_target_z",    default: 0
    t.integer  "number_quota_o",     default: 0
    t.integer  "number_quota_oz",    default: 0
    t.integer  "number_quota_z",     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admission_volumes", ["campaign_id"], name: "index_admission_volumes_on_campaign_id", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.string   "name",             default: ""
    t.integer  "year_start"
    t.integer  "year_end"
    t.integer  "status_id",        default: 1
    t.integer  "campaign_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "competitive_group_items", force: :cascade do |t|
    t.integer  "competitive_group_id"
    t.integer  "number_budget_o",      default: 0
    t.integer  "number_budget_oz",     default: 0
    t.integer  "number_budget_z",      default: 0
    t.integer  "number_paid_o",        default: 0
    t.integer  "number_paid_oz",       default: 0
    t.integer  "number_paid_z",        default: 0
    t.integer  "number_target_o",      default: 0
    t.integer  "number_target_oz",     default: 0
    t.integer  "number_target_z",      default: 0
    t.integer  "number_quota_o",       default: 0
    t.integer  "number_quota_oz",      default: 0
    t.integer  "number_quota_z",       default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "competitive_group_items", ["competitive_group_id"], name: "index_competitive_group_items_on_competitive_group_id", using: :btree

  create_table "competitive_groups", force: :cascade do |t|
    t.integer  "campaign_id"
    t.string   "name",                default: ""
    t.integer  "education_level_id"
    t.integer  "education_source_id"
    t.integer  "education_form_id"
    t.integer  "direction_id"
    t.boolean  "is_for_krym",         default: false
    t.boolean  "is_additional",       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "competitive_groups", ["campaign_id"], name: "index_competitive_groups_on_campaign_id", using: :btree

  create_table "competitive_groups_edu_programs", id: false, force: :cascade do |t|
    t.integer "competitive_group_id", null: false
    t.integer "edu_program_id",       null: false
  end

  create_table "distributed_admission_volumes", force: :cascade do |t|
    t.integer  "admission_volume_id"
    t.integer  "level_budget_id"
    t.integer  "number_budget_o",     default: 0
    t.integer  "number_budget_oz",    default: 0
    t.integer  "number_budget_z",     default: 0
    t.integer  "number_paid_o",       default: 0
    t.integer  "number_paid_oz",      default: 0
    t.integer  "number_paid_z",       default: 0
    t.integer  "number_target_o",     default: 0
    t.integer  "number_target_oz",    default: 0
    t.integer  "number_target_z",     default: 0
    t.integer  "number_quota_o",      default: 0
    t.integer  "number_quota_oz",     default: 0
    t.integer  "number_quota_z",      default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "distributed_admission_volumes", ["admission_volume_id"], name: "index_distributed_admission_volumes_on_admission_volume_id", using: :btree

  create_table "edu_programs", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entrance_test_items", force: :cascade do |t|
    t.integer  "competitive_group_id"
    t.integer  "entrance_test_type_id",  default: 1
    t.integer  "min_score"
    t.integer  "entrance_test_priority"
    t.integer  "subject_id"
    t.string   "subject_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "requests", force: :cascade do |t|
    t.string   "query"
    t.text     "input"
    t.text     "output"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "target_numbers", force: :cascade do |t|
    t.integer  "target_organization_id"
    t.integer  "competitive_group_id"
    t.integer  "number_target_o",        default: 0
    t.integer  "number_target_oz",       default: 0
    t.integer  "number_target_z",        default: 0
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "target_numbers", ["competitive_group_id"], name: "index_target_numbers_on_competitive_group_id", using: :btree
  add_index "target_numbers", ["target_organization_id"], name: "index_target_numbers_on_target_organization_id", using: :btree

  create_table "target_organizations", force: :cascade do |t|
    t.string   "target_organization_name", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "target_numbers", "competitive_groups"
  add_foreign_key "target_numbers", "target_organizations"
end
