class Locality < ApplicationRecord
  validates :reference, presence: true
  validates :properties, presence: true
  validates :lonlat, presence: true
  validates :name, presence: true
  validates :region, presence: true
  validates :country, presence: true
  
  scope :find_by_latitude_and_longitude, -> (latitude, longitude) {
    where("localities.geom IS NOT NULL AND ST_Within(ST_SetSRID(ST_MakePoint(?, ?), 4326), localities.geom)", longitude.to_f, latitude.to_f)
  }

  scope :closest_to, -> (latitude, longitude) {
    order("localities.lonlat <-> ST_SetSRID(ST_MakePoint(#{Arel.sql(longitude.to_f.to_s)}, #{Arel.sql(latitude.to_f.to_s)}), 4326)")
  }
  
  def self.geo_factory
    @geo_factory ||= RGeo::Geographic.spherical_factory(srid: 4326, uses_lenient_assertions: true)
  end

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
    extract_most_seen [
      "ne:ADM0NAME",
      "ne:UN_ADM0",
      "qs:a0",
      "qs:adm0",
      "qs_pg:name_adm0",
      "woe:name_adm0"
    ]
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

  protected

  def extract_most_seen(property_keys)
    properties.values_at(*property_keys).each_with_object(Hash.new(0)) do |value, frequency|
      frequency[value] += 1 if value.present? && value.to_s.length > 1
    end.to_a.max_by(&:last).try(:[], 0)
  end
end
