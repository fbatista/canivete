class RemoveDeviseFromUsers < ActiveRecord::Migration[8.0]
  def self.up
    change_table :users do |t|
      t.remove :encrypted_password
      t.remove :reset_password_token
      t.remove :reset_password_sent_at
      t.remove :remember_created_at
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
