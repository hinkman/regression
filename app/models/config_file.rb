class ConfigFile < ActiveRecord::Base
  has_attached_file  :cf

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :cf
  validates_attachment_file_name :cf, :matches => [/txt\Z/, /yml\Z/]

  has_many :diffs, :dependent => :restrict_with_error

  # default_scope lambda { where("config_files.is_active = 1") }
end
