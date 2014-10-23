class Diff < ActiveRecord::Base
  validates_presence_of :title, :left_id, :right_id, :config_file_id
  validates_uniqueness_of :title
  validate :diff_file_sets

  has_many :results, :dependent => :destroy
  belongs_to :config_file
  belongs_to :left_file_set, :class_name => 'FileSet', :foreign_key => 'left_id'
  belongs_to :right_file_set, :class_name => 'FileSet', :foreign_key => 'right_id'

  # default_scope lambda { where("diffs.is_active = 1") }
  scope :where_last_result_per_diff, lambda { where("results.id in (select a.id from (select id,diff_id from results order by id desc)  a group by a.diff_id)") }

  def diff_file_sets
    if self.left_id == self.right_id
      errors.add(:left_id, "cannot use the same file set for both left and right")
      errors.add(:right, "cannot use the same file set for both left and right")
    end
  end
end
