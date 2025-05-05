class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users do |t|
      t.remove :email

      t.string :email_address, null: false
      t.string :password_digest, null: false
    end
    add_index :users, :email_address, unique: true
  end
end
