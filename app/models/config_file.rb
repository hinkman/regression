class ConfigFile < ActiveRecord::Base
  has_attached_file  :cf

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :cf
  validates_attachment_file_name :cf, :matches => [/txt\Z/, /yml\Z/]

  before_create :randomize_file_name

  has_many :diffs, :dependent => :restrict_with_error

  # default_scope lambda { where("config_files.is_active = 1") }
  ransacker :name_case_insensitive, type: :string do
    arel_table[:name].lower
  end

  private

  def randomize_file_name
    extension = File.extname(cf_file_name).downcase
    self.cf.instance_write(:file_name, "#{SecureRandom.hex(16)}#{extension}")
  end

end
