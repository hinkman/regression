class UsersIsActive < ActiveRecord::Migration
  def change
    add_column :users, :is_active, :integer
    add_column :config_files, :is_active, :integer
    add_column :results, :is_active, :integer
  end
end
