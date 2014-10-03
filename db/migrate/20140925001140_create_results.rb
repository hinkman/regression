class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.integer :diff_id
      t.text :data
      t.boolean :is_complete

      t.timestamps
    end
  end
end
