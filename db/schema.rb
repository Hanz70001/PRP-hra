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

ActiveRecord::Schema[7.1].define(version: 2024_09_24_142613) do
  create_table "t_context_lists", force: :cascade do |t|
    t.text "context_id"
    t.text "context_scopeoflife"
    t.text "context_lastuse"
  end

  create_table "t_context_templates", force: :cascade do |t|
    t.text "context_id"
    t.integer "row_id"
    t.text "row_value"
  end

  create_table "t_contexts", force: :cascade do |t|
    t.text "context_id"
    t.integer "row_id"
    t.text "row_value"
  end

  create_table "t_elements", force: :cascade do |t|
    t.integer "element_type"
    t.integer "width"
    t.integer "height"
    t.text "extrastyle"
    t.text "upi_receive"
    t.text "upi_trigger"
    t.text "upi_onsave"
    t.integer "send_on_change"
    t.text "click_action"
    t.text "tooltip"
    t.text "generaldatalink"
  end

  create_table "t_messagebox", force: :cascade do |t|
    t.string "contextid"
    t.string "message"
  end

  create_table "t_modules", force: :cascade do |t|
    t.string "name"
    t.string "price"
    t.string "weight"
    t.string "image"
    t.string "typeimage"
    t.string "label"
    t.string "eletricity_prod"
    t.string "eletricity_cons"
    t.string "battery_maxcapacity"
    t.string "fuel_maxcapacity"
    t.string "fuel_efectivity"
    t.string "fuel_constype"
    t.string "engine_power"
    t.string "engine_cons"
    t.string "radar_bonus"
    t.string "research_rate"
    t.string "research_consumption"
    t.string "shield_strenght"
    t.string "shield_cons"
    t.string "health_bonus"
  end

  create_table "t_pages", force: :cascade do |t|
    t.integer "page_id"
    t.integer "record_type"
    t.integer "panel_id"
    t.string "position_type"
    t.string "position_values"
    t.string "cycling_settings"
    t.string "cycling_count"
    t.string "data_inheritance_style"
    t.string "creation_condition"
    t.string "action_generaldatalink"
    t.string "action_determination"
    t.string "action_value"
  end

  create_table "t_panels", force: :cascade do |t|
    t.integer "panel_id"
    t.integer "element_id"
    t.string "position_type"
    t.string "position_values"
    t.string "cycling_settings"
    t.string "cycling_count"
    t.string "data_inheritance_style"
    t.string "creation_condition"
  end

  create_table "t_players", force: :cascade do |t|
    t.string "contextid"
    t.string "cashbalance"
    t.string "maxdistance"
    t.string "launchcount"
  end

  create_table "t_possiblevalues", force: :cascade do |t|
    t.text "group_name"
    t.text "value_realvalue"
    t.text "value_labelvalue"
  end

  create_table "t_satellite_list", force: :cascade do |t|
    t.string "contextid"
    t.string "satellitename"
  end

  create_table "t_satellite_template", force: :cascade do |t|
    t.string "contextid"
    t.string "moduleid"
  end

  create_table "t_satellite_values", force: :cascade do |t|
    t.string "satellitename"
    t.string "image"
    t.string "status"
    t.string "distance"
    t.string "totalweight"
    t.string "speed"
    t.string "timeofstart"
    t.string "battery_maxcapacity"
    t.string "battery_stateofcharge"
    t.string "total_eleprod"
    t.string "total_elecons"
    t.string "total_shield"
    t.string "total_resrate"
    t.string "radar_cons"
    t.string "maxhealth"
    t.string "currenthealth"
    t.string "danger_time"
    t.string "danger_strenght"
    t.string "danger_type"
    t.string "lasttick_time"
  end

  create_table "t_sattelite_contruction", force: :cascade do |t|
    t.string "satellitename"
    t.string "poweronstatus"
    t.string "name"
    t.string "image"
    t.string "typeimage"
    t.string "label"
    t.string "eletricity_prod"
    t.string "eletricity_cons"
    t.string "fuel_maxcapacity"
    t.string "fuel_stateofcharge"
    t.string "fuel_efectivity"
    t.string "fuel_constype"
    t.string "engine_power"
    t.string "engine_cons"
    t.string "research_rate"
    t.string "research_consumption"
    t.string "shield_strenght"
    t.string "shield_cons"
  end

  create_table "t_serveroptions", force: :cascade do |t|
    t.text "option_name"
    t.text "option_value"
  end

  create_table "t_users", force: :cascade do |t|
    t.text "user_name"
    t.text "user_validation"
    t.text "user_machineid"
    t.datetime "user_lastpresence"
    t.text "user_contextid"
  end

end
