class CreateServerOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :t_serveroptions, id: false do |t|
      t.primary_key :id
      t.text :option_name
      t.text :option_value
    end
  end
end
