class FileSet < ActiveRecord::Base
  mount_uploader :path, FileSetUploader

  validates_presence_of :name, :path
  validates_uniqueness_of :name

  has_many :diffs_left_id, :class_name => 'Diff', :foreign_key => 'left_id'
  has_many :diffs_right_id, :class_name => 'Diff', :foreign_key => 'right_id'

  default_scope lambda { where("is_active = 1") }

end
