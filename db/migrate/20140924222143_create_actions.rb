class CreateActions < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.string :action
      t.string :item
      t.integer :item_id
      t.integer :user_id
      t.string :description

      t.timestamps
    end

    remove_column :diffs, :created_by
    remove_column :diffs, :updated_by
    remove_column :diffs, :last_run_by
    remove_column :diffs, :last_run_at
    remove_column :diffs, :deleted_at

    add_column :diffs, :is_active, :boolean
    add_column :diffs, :action_id, :integer

  end
end
