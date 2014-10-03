class DiffChanges < ActiveRecord::Migration
  def change
    remove_column :diffs, :config_file

    add_column :diffs, :config_id, :integer
    add_column :diffs, :left_id, :integer
    add_column :diffs, :right_id, :integer

  end
end
