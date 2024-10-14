class CreatePossibleValues < ActiveRecord::Migration[7.1]
  def change
    create_table :t_possiblevalues, id: false do |t|
      t.primary_key :id
      t.text :group_name
      t.text :value_realvalue
      t.text :value_labelvalue
    end
  end
end
