class RemoveActionId < ActiveRecord::Migration
  def change
    remove_column :file_sets, :action_id
    remove_column :config_files, :action_id
  end
end
