class CreateUsers < ActiveRecord::Migration
  def change
    drop_table :users

    create_table :users do |t|
      t.string :user_name
      t.string :first_name
      t.string :last_name
      t.string :email
      t.datetime :last_login_at

      t.timestamps
    end

    change_column :diffs, :created_by, :integer
    change_column :diffs, :updated_by, :integer
    change_column :diffs, :last_run_by, :integer
  end
end
