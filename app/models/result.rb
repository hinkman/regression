class Result < ActiveRecord::Base
  validates_presence_of :diff_id, :pct_complete

  belongs_to :diff

  # default_scope lambda { where("results.is_active = 1") }
  scope :where_diff_id, lambda { |term| where("diff_id = ?", term) }

end
