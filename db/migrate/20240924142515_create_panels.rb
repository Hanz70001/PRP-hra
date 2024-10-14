class CreatePanels < ActiveRecord::Migration[7.0]
  def change
    create_table :t_panels, id: false do |t|
      t.primary_key :id
      t.integer :panel_id
      t.integer :element_id
      t.string :position_type
      t.string :position_values
      t.string :cycling_settings
      t.string :cycling_count
      t.string :data_inheritance_style
      t.string :creation_condition
    end
  end
end