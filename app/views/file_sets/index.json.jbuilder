json.array!(@file_sets) do |file_set|
  json.extract! file_set, :id, :name, :description, :path
  json.url file_set_url(file_set, format: :json)
end
