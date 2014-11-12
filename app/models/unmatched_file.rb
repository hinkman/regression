class UnmatchedFile < ActiveRecord::Base
  validates_presence_of :result_id, :side, :name, :url

  belongs_to :result

  # default_scope lambda { |result_id| where('result_id = ?', result_id) }
  scope :where_result_id_and_side, lambda { |result_id,side| where('result_id = ? and side = ?', result_id, side) }

end
