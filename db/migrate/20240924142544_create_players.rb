class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :t_players, id: false do |t|
      t.primary_key :id
      t.string :contextid
      t.string :cashbalance
      t.string :maxdistance
      t.string :launchcount
    end
  end
end