class CreateConfigFiles < ActiveRecord::Migration
  def change
    create_table :config_files do |t|
      t.string :name
      t.text :description
      t.text :data
      t.integer :version
      t.integer :action_id

      t.timestamps
    end
  end
end
