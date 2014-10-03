class RemoveActionFromDiffs < ActiveRecord::Migration
  def change
    remove_column :diffs, :action_id
  end
end
