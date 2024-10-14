class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :t_users, id: false do |t|
      t.primary_key :id
      t.text :user_name
      t.text :user_validation
      t.text :user_machineid
      t.datetime :user_lastpresence
      t.text :user_contextid
    end
  end
end
