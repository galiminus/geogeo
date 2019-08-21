class Locality < Geometry
  validates :reference, presence: true
  validates :properties, presence: true
  validates :lonlat, presence: true
  validates :name, presence: true, if: -> { region.blank? && country.blank? }
  validates :region, presence: true, if: -> { country.blank? && name.blank? }
  validates :country, presence: true, if: -> { region.blank? && name.blank? }
  
  def as_json(options = {})
    {
      name: name,
      region: region,
      country: country,
      latitude: latitude,
      longitude: longitude,
    }
  end

  def name
    extract_most_seen [
      "wof:name",
      "ne:NAME",
      "ne:MEGANAME",
      "ne:NAMEASCII",
      "ne:GNASCII",
      "ne:LS_NAME",
      "qs:loc",
      "qs:loc_alt",
      -> { properties['name:eng_x_preferred'].try(:[], 0) }
    ]
  end

  def region
    extract_most_seen([
      "ne:ADM1NAME",
      "qs:a1r",
      "qs_pg:name_adm1",
      "woe:name_adm1",
      "qs:a1"
    ])&.sub(/^[0-9\*]+/, '')
  end

  def country
    country_from_iso = ISO3166::Country.new(properties['iso:country'])

    if country_from_iso.present?
      country_from_iso.translations['en']
    else
      extract_most_seen [
        "ne:ADM0NAME",
        "ne:UN_ADM0",
        "qs:a0",
        "qs:adm0",
        "qs_pg:name_adm0",
        "woe:name_adm0",
        -> {
          Country.find_by_latitude_and_longitude(latitude, longitude).limit(1).first&.name ||
             Country.closest_to(latitude, longitude).limit(1).first&.name
        }
      ]
    end
  end

  def latitude
    extract_most_seen [
      "lbl:latitude",
      "mps:latitude",
      "geom:latitude",
      "ne:LATITUDE",
      "reversegeo:latitude"
    ]
  end

  def longitude
    extract_most_seen [
      "lbl:longitude",
      "mps:longitude",
      "geom:longitude",
      "ne:LONGITUDE",
      "reversegeo:longitude"
    ]
  end

  def self.best_matches(latitude, longitude)
    locality_within = Locality.find_by_latitude_and_longitude(latitude, longitude)

    if locality_within.present?
      locality_within
    else
      Locality.closest_to(latitude, longitude)
    end
  end
end
