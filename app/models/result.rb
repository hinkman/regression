class Result < ActiveRecord::Base
  validates_presence_of :diff_id, :is_complete

  belongs_to :diff
end
