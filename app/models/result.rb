class Result < ActiveRecord::Base
  validates_presence_of :diff_id, :pct_complete

  belongs_to :diff
end
