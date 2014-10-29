class UnmatchedFile < ActiveRecord::Base
  validates_presence_of :result_id, :side, :name, :url
  belongs_to :result
  default_scope lambda { |result_id,side| where('result_id = ? and side = ?', result_id, side) }
end
