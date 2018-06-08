require 'spy_glass/registry'

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

puts opts[:source]

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    # TODO handle nil cases better
    title = <<-TITLE.oneline
    A new #{item.fetch('permit_type', '').titleize} permit has been issued at #{item.fetch('permit_address', 'unknown address').titleize} to #{item.fetch('agent', 'unknown').titleize} with id #{item['permit_number']}. Contact #{item['contact']} with any questions.
  TITLE

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
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
