class User < ActiveRecord::Base
  include Adauth::Rails::ModelBridge

  AdauthMappings = {
      :login => :login
  }

  AdauthSearchField = [:login, :login]

  validates_presence_of :login, :email
  validates_uniqueness_of :login
  validates_length_of :email, :within => 10..50, :message => 'has invalid length'
  validates_format_of :email, :with =>  /\A[^@][\w.-]+@[\w.-]+[.][a-z]{2,4}\z/i, :message => 'has invalid format'
  validates_presence_of :last_login_at, :on => :update

  has_many :actions, :dependent => :destroy

  default_scope lambda { where("is_active = 1") }

end
