class CreateSatelliteTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :t_satellite_template, id: false do |t|
      t.primary_key :id
      t.string :contextid
      t.string :moduleid
    end
  end
end