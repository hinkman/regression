class CreateDiffs < ActiveRecord::Migration
  def change
    create_table :diffs do |t|
      t.string        :title
      t.string        :created_by
      t.string        :modified_by
      t.datetime      :last_run_at
      t.string        :last_run_by
      t.text          :description
      t.integer       :config_file
      t.string        :directory
      t.datetime      :deleted_at

      t.timestamps
    end
  end
end
