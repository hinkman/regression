class FileSet < ActiveRecord::Base
  has_attached_file  :fs

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_attachment :fs, :presence => true, content_type: { :content_type => /\Atext\/.*\Z/ }

  has_many :diffs_left, :class_name => 'Diff', :foreign_key => 'left_id'
  has_many :diffs_right, :class_name => 'Diff', :foreign_key => 'right_id'

  default_scope lambda { where("file_sets.is_active = 1") }

end
