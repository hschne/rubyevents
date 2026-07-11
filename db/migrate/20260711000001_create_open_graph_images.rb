class CreateOpenGraphImages < ActiveRecord::Migration[8.2]
  def change
    create_table :open_graph_images do |t|
      t.timestamps
    end
  end
end
