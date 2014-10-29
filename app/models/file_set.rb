class FileSet < ActiveRecord::Base
  has_attached_file  :fs

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :fs
  validates_attachment_file_name :fs, :matches => [/zip\Z/, /tgz\Z/]

  before_create :randomize_file_name


  has_many :diffs_left, :class_name => 'Diff', :foreign_key => 'left_id', :dependent => :restrict_with_error
  has_many :diffs_right, :class_name => 'Diff', :foreign_key => 'right_id', :dependent => :restrict_with_error

  # default_scope lambda { where("file_sets.is_active = 1") }

  ransacker :name_case_insensitive, type: :string do
    arel_table[:name].lower
  end

  private

  def randomize_file_name
    extension = File.extname(fs_file_name).downcase
    self.fs.instance_write(:file_name, "#{SecureRandom.hex(16)}#{extension}")
  end

end
