class CreateContextTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :t_context_templates, id: false do |t|
      t.primary_key :id
      t.text :context_id
      t.integer :row_id
      t.text :row_value
    end
  end
end
