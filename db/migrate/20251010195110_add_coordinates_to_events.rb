class AddCoordinatesToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :lng, :decimal
    add_column :events, :lat, :decimal
  end
end
