class CreateContextLists < ActiveRecord::Migration[7.1]
  def change
    create_table :t_context_lists, id: false do |t|
      t.primary_key :id
      t.text :context_id
      t.text :context_scopeoflife
      t.text :context_lastuse
    end
  end
end
