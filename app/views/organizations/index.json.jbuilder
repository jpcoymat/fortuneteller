json.array!(@organizations) do |organization|
  json.extract! organization, :id, :name, :address_1, :city, :organization_type
  json.url organization_url(organization, format: :json)
end
