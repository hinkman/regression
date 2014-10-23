class Result < ActiveRecord::Base
  validates_presence_of :diff_id, :pct_complete

  belongs_to :diff

  default_scope lambda { order("updated_at desc") }
  # default_scope lambda { where("results.id in (select a.id from (select id,diff_id from results order by id desc)  a group by a.diff_id)") }
  scope :where_diff_id, lambda { |term| where("diff_id = ?", term) }
  scope :where_last_result_per_diff, lambda { where("results.id in (select a.id from (select id,diff_id from results order by id desc)  a group by a.diff_id)") }

end
