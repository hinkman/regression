class UnsuccessfulFile < ActiveRecord::Base
  validates_presence_of :result_id, :left_line_number, :right_line_number, :left_line, :right_line, :compare_key

  belongs_to :result

  # default_scope lambda { |result_id| where('result_id = ?', result_id) }
  scope :where_result_id, lambda { |result_id| where('result_id = ?', result_id) }
  scope :where_compare_key_and_not_line_zero, lambda { |compare_key| where('compare_key = ? and (left_line_number > 0 or right_line_number > 0)', compare_key) }

end
