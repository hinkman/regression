class Diff < ActiveRecord::Base
  validates_presence_of :title
  validates_uniqueness_of :title

  has_many :results, :dependent => :destroy
  belongs_to :config_file
  belongs_to :left_file_set, :class_name => 'FileSet', :foreign_key => 'left_id'
  belongs_to :right_file_set, :class_name => 'FileSet', :foreign_key => 'right_id'

  default_scope lambda { where("diffs.is_active = 1") }

end
