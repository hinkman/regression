class RemovePathFromDiffs < ActiveRecord::Migration
  def change
    remove_column :diffs, :path
  end
end
