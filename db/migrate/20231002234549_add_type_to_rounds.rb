class AddTypeToRounds < ActiveRecord::Migration[7.0]
  def change
    add_column :rounds, :type, :string, default: 'SwissRound'
  end
end
