class Result < ActiveRecord::Base
  validates_presence_of :diff_id, :pct_complete

  # TODO result descriptions
  belongs_to :diff
  has_many :unmatched_files

  default_scope lambda { order("updated_at desc") }
  scope :where_diff_id, lambda { |term| where("diff_id = ?", term) }

end
