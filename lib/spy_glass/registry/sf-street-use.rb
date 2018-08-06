require 'spy_glass/registry'

# load type dictionary
# creates hash of permit type to description
permit_types = SpyGlass::Client::Socrata.new({
  path: '/sf-street-use-types',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  content_type: 'application/json',
  generator: SpyGlass::Client::Base::IDENTITY,
  source: 'https://data.sfgov.org/resource/kzxg-e2hm.json',
}) do |collection|
  Hash[collection.map(&:values)].invert
end.cooked

opts = {
  path: '/sf-street-use',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.sfgov.org/resource/6aba-tvpi.json?'+Rack::Utils.build_query({
    # TODO iterate over paginated results
    '$limit' => 20000,
    '$order' => 'permit_number ASC',
    '$where' => <<-WHERE.oneline
      approved_date >= '#{7.days.ago.strftime('%Y-%m-%d')}'
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    # TODO handle nil cases better
    title = <<-TITLE.oneline
    A new #{item.fetch('permit_type', '').titleize} permit has been issued at #{item.fetch('permit_address', 'unknown address').titleize} to #{item.fetch('agent', 'unknown').titleize} with id #{item['permit_number']}. Contact #{item['contact']} with any questions.
  TITLE

    location = item['permit_address'] ? item['permit_address'] : item['streetname']
    if item['cross_street_1'] && item['cross_street_2']
      location += ", between #{item['cross_street_1']} and #{item['cross_street_2']}"
    end

    {
      'id' => item['permit_number'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['longitude'].to_f,
          item['latitude'].to_f
        ]
      },

      # will iterate on this to come up with normalized properties for the custom front-end
      # https://github.com/SFDigitalServices/neighborhood-noticing
      'properties' => {
        # required by Citygram
        'id' => item['permit_number'],
        'title' => title,

        'type' => permit_types[item['permit_type']],
        'description' => item['permit_purpose'],
        'originator' => item['agent'],
        'originator_phone' => item['agentphone'],
        'status' => item['status'],
        'location' => location,
        'start' => item['start_date'],
        'end' => item['end_date'],
      },
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
