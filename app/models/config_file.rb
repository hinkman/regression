class ConfigFile < ActiveRecord::Base
  has_attached_file  :cf

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_attachment :cf, :presence => true, content_type: { :content_type => /\Atext\/.*\Z/ }

  has_many :diffs

  default_scope lambda { where("config_files.is_active = 1") }
end
