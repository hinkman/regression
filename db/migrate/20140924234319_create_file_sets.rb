class CreateFileSets < ActiveRecord::Migration
  def change
    create_table :file_sets do |t|
      t.string :name
      t.text :description
      t.integer :action_id
      t.string :path
      t.boolean :is_active

      t.timestamps
    end
  end
end
