class DiffPath < ActiveRecord::Migration
  def change
    rename_column :diffs, :directory, :path
  end
end
