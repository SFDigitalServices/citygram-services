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

# TODO see if we can get this data into the SF Street-Use Permit Types dataset
permit_type_metadata = {
  "AddlStSpac" => {
    "description" => "Allows occupation of: \n- more than half the sidewalk\n- the road area that cars travel on, past the parking lane \n- the front of more than one property",
    "link" => "https://www.sfpublicworks.org/services/permits/additional-street-space",
  },
  "AnnualSC" => {
    "description" => "Allows a storage container to be placed in the street or sidewalk, on an annual basis. Container should not occupy more than the street's parking lane, nor completely block pedestrian sidewalk traffic.",
    "link" => "null",
  },
  "Banners" => {
    "description" => "Allows a nonprofit or cultural organization to advertise a City-supported public event on utility poles.",
    "link" => "https://www.sfpublicworks.org/services/permits/banners",
  },
  "Bicycle" => {
    "description" => "Bicycle Rack",
    "link" => "null",
  },
  "Boring" => {
    "description" => "Allows a licensed contractor to bore or install a monitoring well in a street or sidewalk",
    "link" => "https://www.sfpublicworks.org/services/permits/boring-and-monitoring-well",
  },
  "CommemPl" => {
    "description" => "Allows a commerative plaque to be placed in a public street or sidewalk.",
    "link" => "null",
  },
  "conformity" => {
    "description" => "null",
    "link" => "https://www.sfpublicworks.org/services/permits/inspection-conformity",
  },
  "DebrisBox" => {
    "description" => "Allows a construction waste dumpster to be placed in the street, following traffic and parking regulations.",
    "link" => "https://www.sfpublicworks.org/services/permits/debris-box-permit",
  },
  "Display" => {
    "description" => "Allows retailers to display merchadise on the sidewalk in front of their business.",
    "link" => "https://www.sfpublicworks.org/services/permits/display-merchandise",
  },
  "Emergency" => {
    "description" => "Emergency Confirmation Number",
    "link" => "null",
  },
  "Excavation" => {
    "description" => "Allows digging into public streets or sidewalks.",
    "link" => "https://www.sfpublicworks.org/services/permits/utility-excavation",
  },
  "ExcStreet" => {
    "description" => "Allows a licensed contractor to excavate and restore pavement when replacing utilities.",
    "link" => "https://www.sfpublicworks.org/services/permits/general-excavation",
  },
  "FoodFac" => {
    "description" => "Allows a food truck or cart to operate on a public street or sidewalk.",
    "link" => "https://www.sfpublicworks.org/services/permits/mobile-food-facilities",
  },
  "FreeSample" => {
    "description" => "Allows businesses to give away promotional samples on public sidewalks or streets. This permit does not allow furniture to be placed in the street.",
    "link" => "https://www.sfpublicworks.org/services/permits/free-sample-merchandise",
  },
  "MajorEnc" => {
    "description" => "Special allowance by the Board of Supervisors to take over a sidewalk or street.",
    "link" => "https://www.sfpublicworks.org/services/permits/major-encroachment",
  },
  "MinorEnc" => {
    "description" => "Allows for public sidewalk ameneties, such as fences, walls, steps, planters, or benches.",
    "link" => "https://www.sfpublicworks.org/services/permits/minor-encroachment-permit",
  },
  "MiscServ" => {
    "description" => "Miscellaneous Services",
    "link" => "null",
  },
  "NightNoise" => {
    "description" => "Allows construction between 8pm and 7am. After 10pm, only hand tools are allowed.",
    "link" => "https://www.sfpublicworks.org/services/permits/night-noise",
  },
  "Other" => {
    "description" => "Test Other",
    "link" => "null",
  },
  "OverwideDr" => {
    "description" => "Allows the construction of a driveway wider than 30 feet.",
    "link" => "https://www.sfbetterstreets.org/design-guidelines/driveways/\n\nhttps://sfpublicworks.org/sites/default/files/5041-Permitting%20and%20Required%20Final%20Approvals.pdf",
  },
  "Parklet" => {
    "description" => "Allows the installation of sidewalk landscaping.",
    "link" => "https://www.sfpublicworks.org/services/permits/parklets",
  },
  "PipeBarr" => {
    "description" => "Allows the installation of vertical posts separating a public street from sidewalk.",
    "link" => "https://www.sfbetterstreets.org/find-project-types/streetscape-elements/street-furniture-overview/bollards/",
  },
  "Referral" => {
    "description" => "Referral Request",
    "link" => "null",
  },
  "Shelters" => {
    "description" => "Allows construction of a transit stop shelter.",
    "link" => "null",
  },
  "SideSewer" => {
    "description" => "Allows a licensed contractor to install a sewer running through a sidewalk or street.",
    "link" => "https://www.sfpublicworks.org/services/permits/side-sewer",
  },
  "Sidewalk" => {
    "description" => "To fix missing, uneven, or cracked sidewalks.",
    "link" => "https://www.sfpublicworks.org/services/permits/sidewalk-repair",
  },
  "SpecSide" => {
    "description" => "Allows non-concrete sidewalk paving to be used.",
    "link" => "null",
  },
  "StorCont" => {
    "description" => "Allows a storage container to be temporarilty placed in the street or sidewalk. Container should not occupy more than the street's parking lane, nor completely block pedestrian sidewalk traffic.",
    "link" => "https://www.sfpublicworks.org/services/permits/storage-container",
  },
  "StreetSpace" => {
    "description" => "Allows occupation of:\n- less than half the sidewalk\n- a street's parking lane\n- the front of one property",
    "link" => "https://www.sfpublicworks.org/services/permits/street-space",
  },
  "StrtImprov" => {
    "description" => "Required when building construction work affects a public sidewalk or street.",
    "link" => "https://www.sfpublicworks.org/services/permits/street-improvement",
  },
  "SurfaceFac" => {
    "description" => "Allows a metal cabinet to be installed on the sidewalk, for electric service, communications, traffic signals, or ticket vending machines.",
    "link" => "https://www.sfpublicworks.org/services/permits/surface-mounted-facility",
  },
  "TableChair" => {
    "description" => "Allows restaurants to provide outdoor seating on the sidewalk.",
    "link" => "https://www.sfpublicworks.org/services/permits/cafe-tables-and-chairs",
  },
  "TankAband" => {
    "description" => "null",
    "link" => "null",
  },
  "TankRemove" => {
    "description" => "Allows the removal of a storage tank from under the street. These tanks usually keep hazardous substances from contaminating the soil or water.",
    "link" => "https://www.sfpublicworks.org/services/permits/tank-removal",
  },
  "TempOccup" => {
    "description" => "Allows construction or street work in a public sidewalk or street. No excavation is allowed on this permit.",
    "link" => "https://www.sfpublicworks.org/services/permits/temporary-occupancy",
  },
  "Vault" => {
    "description" => "Allows an electrical transformer vault to be placed on public property.",
    "link" => "https://www.sfpublicworks.org/services/permits/vault-transformer",
  },
  "Wireless" => {
    "description" => "Allows wireless antennas and equipment to be installed on utility or light poles.",
    "link" => "https://www.sfpublicworks.org/services/permits/wireless-service-facilities",
  },
  "WirelessUPD" => {
    "description" => "Allows wireless antennas and equipment to be changed or fixed.",
    "link" => "null",
  }
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

    permit_type = item['permit_type']

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

        'type' => {
          'name' => 'Permit',

          'subtype' => {
            'name' => permit_types[permit_type],
            'description' => permit_type_metadata[permit_type]&.description,
            'link' => permit_type_metadata[permit_type]&.link,
          }
        },

        'description' => item['permit_purpose'],
        'originator' => item['agent'],
        'originator_phone' => item['agentphone'],
        'status' => item['status'],
        'location' => location,
        'start' => item['permit_start_date'],
        'end' => item['permit_end_date'],
      },
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
