class ChangeColumnName < ActiveRecord::Migration
  def change
    rename_column :diffs, :modified_by, :updated_by
  end
end
