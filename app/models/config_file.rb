class ConfigFile < ActiveRecord::Base
  mount_uploader :path, ConfigFileUploader

  validates_presence_of :name, :path
  validates_uniqueness_of :name

  has_many :diffs

  default_scope lambda { where("is_active = 1") }
end
