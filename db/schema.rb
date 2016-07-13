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

ActiveRecord::Schema.define(version: 20160713085214) do

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
    t.integer  "education_forms",               array: true
    t.integer  "education_levels",              array: true
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

  create_table "competitive_groups_entrance_test_items", id: false, force: :cascade do |t|
    t.integer "competitive_group_id",  null: false
    t.integer "entrance_test_item_id", null: false
  end

  create_table "competitive_groups_entrant_applications", id: false, force: :cascade do |t|
    t.integer "entrant_application_id", null: false
    t.integer "competitive_group_id",   null: false
  end

  create_table "distributed_admission_volumes", force: :cascade do |t|
    t.integer  "admission_volume_id"
    t.integer  "level_budget_id"
    t.integer  "number_budget_o",     default: 0
    t.integer  "number_budget_oz",    default: 0
    t.integer  "number_budget_z",     default: 0
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

  create_table "education_documents", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.string   "education_document_type"
    t.string   "education_document_series"
    t.string   "education_document_number"
    t.date     "education_document_date"
    t.date     "original_received_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "education_documents", ["entrant_application_id"], name: "index_education_documents_on_entrant_application_id", using: :btree

  create_table "entrance_test_items", force: :cascade do |t|
    t.integer  "entrance_test_type_id",  default: 1
    t.integer  "min_score"
    t.integer  "entrance_test_priority"
    t.integer  "subject_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "entrant_applications", force: :cascade do |t|
    t.integer  "registration_number"
    t.integer  "application_number"
    t.integer  "campaign_id"
    t.string   "entrant_last_name"
    t.string   "entrant_first_name"
    t.string   "entrant_middle_name"
    t.integer  "gender_id"
    t.date     "birth_date"
    t.integer  "region_id"
    t.string   "email"
    t.date     "registration_date"
    t.boolean  "need_hostel",            default: false
    t.integer  "status_id",              default: 2
    t.integer  "nationality_type_id"
    t.integer  "target_organization_id"
    t.boolean  "special_entrant",        default: false
    t.boolean  "olympionic",             default: false
    t.boolean  "benefit",                default: false
    t.string   "data_hash"
    t.boolean  "checked",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "entrant_applications_identity_documents", id: false, force: :cascade do |t|
    t.integer "entrant_application_id", null: false
    t.integer "identity_document_id",   null: false
  end

  create_table "entrant_applications_institution_achievements", id: false, force: :cascade do |t|
    t.integer "entrant_application_id",     null: false
    t.integer "institution_achievement_id", null: false
  end

  create_table "identity_documents", force: :cascade do |t|
    t.integer  "identity_document_type"
    t.string   "identity_document_series"
    t.string   "identity_document_number"
    t.date     "identity_document_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "identity_documents", ["identity_document_type"], name: "index_identity_documents_on_identity_document_type", using: :btree

  create_table "institution_achievements", force: :cascade do |t|
    t.string   "name"
    t.integer  "id_category"
    t.integer  "max_value"
    t.integer  "campaign_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "institution_achievements", ["campaign_id"], name: "index_institution_achievements_on_campaign_id", using: :btree

  create_table "marks", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.integer  "subject_id"
    t.integer  "value"
    t.string   "form"
    t.date     "checked"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "marks", ["entrant_application_id"], name: "index_marks_on_entrant_application_id", using: :btree
  add_index "marks", ["subject_id"], name: "index_marks_on_subject_id", using: :btree

  create_table "requests", force: :cascade do |t|
    t.string   "query"
    t.text     "input"
    t.text     "output"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subjects", force: :cascade do |t|
    t.integer  "subject_id"
    t.string   "subject_name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
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
