class AddKeys < ActiveRecord::Migration
  def change
    add_foreign_key "actions", "users", name: "actions_user_id_fk"
    add_foreign_key "diffs", "config_files", name: "diffs_config_file_id_fk"
    add_foreign_key "diffs", "file_sets", name: "diffs_right_id_fk", column: "right_id"
    add_foreign_key "diffs", "file_sets", name: "diffs_left_id_fk", column: "left_id"
    add_foreign_key "results", "diffs", name: "results_diff_id_fk"
  end
end
