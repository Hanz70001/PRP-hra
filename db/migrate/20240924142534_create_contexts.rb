class CreateContexts < ActiveRecord::Migration[7.1]
  def change
    create_table :t_contexts, id: false do |t|
      t.primary_key :id
      t.text :context_id
      t.integer :row_id
      t.text :row_value
    end
  end
end
