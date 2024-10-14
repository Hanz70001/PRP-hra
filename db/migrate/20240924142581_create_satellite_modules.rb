class CreateSatelliteModules < ActiveRecord::Migration[7.1]
  def change
    create_table :t_modules, id: false do |t|
      t.primary_key :id
      t.string :name
      t.string :price
      t.string :weight
      t.string :image
      t.string :typeimage
      t.string :label
      t.string :eletricity_prod
      t.string :eletricity_cons
      t.string :battery_maxcapacity
      t.string :fuel_maxcapacity
      t.string :fuel_efectivity
      t.string :fuel_constype
      t.string :engine_power
      t.string :engine_cons
      t.string :radar_bonus
      t.string :research_rate
      t.string :research_consumption
      t.string :shield_strenght
      t.string :shield_cons
      t.string :health_bonus
    end
  end
end