class UsersAddGroup < ActiveRecord::Migration
  def change
    add_column :users, :group_strings, :text
    rename_column :users, :user_name, :login
  end
end
