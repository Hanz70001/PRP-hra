class CreateMessageBoxs < ActiveRecord::Migration[7.1]
  def change
    create_table :t_messagebox, id: false do |t|
      t.primary_key :id
      t.string :contextid
      t.string :message
    end
  end
end