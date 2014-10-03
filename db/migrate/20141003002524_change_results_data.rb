class ChangeResultsData < ActiveRecord::Migration
  def change
    rename_column :results, :data, :path
  end
end
