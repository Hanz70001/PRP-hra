class CreateSatelliteLists < ActiveRecord::Migration[7.1]
  def change
    create_table :t_satellite_list, id: false do |t|
      t.primary_key :id
      t.string :contextid
      t.string :satellitename
    end
  end
end