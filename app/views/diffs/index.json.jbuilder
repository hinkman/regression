json.array!(@diffs) do |diff|
  json.extract! diff, :id, :title, :description, :config_file_id, :left_id, :right_id
  json.url diff_url(diff, format: :json)
end
