class RenameConfigFileData < ActiveRecord::Migration
  def change
    rename_column :config_files, :data, :path
  end
end
