class CreatePages < ActiveRecord::Migration[7.0]
  def change
    create_table :t_pages, id: false do |t|
      t.primary_key :id
      t.integer :page_id
      t.integer :record_type
      t.integer :panel_id
      t.string :position_type
      t.string :position_values
      t.string :cycling_settings
      t.string :cycling_count
      t.string :data_inheritance_style
      t.string :creation_condition
      t.string :action_generaldatalink
      t.string :action_determination
      t.string :action_value
    end
  end
end