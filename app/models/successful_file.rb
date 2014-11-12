class SuccessfulFile < ActiveRecord::Base
  validates_presence_of :result_id, :left_name, :right_name

  belongs_to :result

  # default_scope lambda { |result_id| where('result_id = ?', result_id) }
  scope :where_result_id, lambda { |result_id| where('result_id = ?', result_id) }

end
