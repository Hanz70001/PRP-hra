class CreateElements < ActiveRecord::Migration[7.0]
  def change
    create_table :t_elements, id: false do |t|
      t.primary_key :id
      t.integer :element_type
      t.integer :width
      t.integer :height
      t.text :extrastyle
      t.text :upi_receive
      t.text :upi_trigger
      t.text :upi_onsave
      t.integer :send_on_change
      t.text :click_action
      t.text :tooltip
      t.text :generaldatalink
    end
  end
end