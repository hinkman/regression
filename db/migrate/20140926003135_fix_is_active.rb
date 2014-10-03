class FixIsActive < ActiveRecord::Migration
  def change
    change_column :users, :is_active, :boolean
    change_column :config_files, :is_active, :boolean
    change_column :results, :is_active, :boolean
  end
end
