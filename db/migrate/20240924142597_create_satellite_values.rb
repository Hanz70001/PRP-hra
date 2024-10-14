class CreateSatelliteValues < ActiveRecord::Migration[7.1]
  def change
    create_table :t_satellite_values, id: false do |t|
      t.primary_key :id
      t.string :satellitename
      t.string :image
      t.string :status
      t.string :distance
      t.string :totalweight
      t.string :speed
      t.string :timeofstart
      t.string :battery_maxcapacity
      t.string :battery_stateofcharge
      t.string :total_eleprod
      t.string :total_elecons
      t.string :total_shield
      t.string :total_resrate
      t.string :radar_cons
      t.string :maxhealth
      t.string :currenthealth
      t.string :danger_time
      t.string :danger_strenght
      t.string :danger_type
      t.string :lasttick_time
    end
  end
end