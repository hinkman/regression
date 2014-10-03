class Action < ActiveRecord::Base
  validates_presence_of :action, :item, :item_id, :user_id
  validates_inclusion_of :action, :in => %w( create upload update run delete destroy ), :message => 'is not valid'
  validates_inclusion_of :item, :in => %w( user config_file diff file_set ), :message => 'is not valid'

  has_one :diff, :dependent => :nullify
  has_one :file_set, :dependent => :nullify
  has_one :config_file, :dependent => :nullify
  belongs_to :user
end
