class DiffConfigFileName < ActiveRecord::Migration
  def change

    rename_column :diffs, :config_id, :config_file_id

  end
end
