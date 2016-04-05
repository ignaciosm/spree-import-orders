class CreateOrderImports < ActiveRecord::Migration
  def change
    create_table :spree_order_imports do |t|
      t.string :data_file_file_name
      t.string :data_file_content_type
      t.integer :data_file_file_size
      t.datetime :data_file_updated_at
      t.text :order_ids
      t.string :state
      t.datetime :failed_at
      t.datetime :completed_at
      t.timestamps
    end
  end
end
