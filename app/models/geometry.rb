class Geometry < ApplicationRecord
  GEOMETRY_CONTAINERS = {
    region: Region,
    macroregion: MacroRegion,
    county: County,
    country: Country,
    empire: Empire
  }

  validates :reference, presence: true
  validates :properties, presence: true
  validates :lonlat, presence: true
  validates :name, presence: true

  before_save :set_cached_name
  before_save :set_cached_hierarchy

  def set_cached_hierarchy
    self.cached_hierarchy = GEOMETRY_CONTAINERS.map do |geometry, _|
      [geometry, send(geometry)&.cached_name]
    end.select do |geometry, name|
      name.present?
    end.to_h
  end

  def as_json(options = {})
    {
      reference: reference,
      name: cached_name,
      hierarchy: cached_hierarchy,
    }
  end

  scope :find_by_latitude_and_longitude, -> (latitude, longitude) {
    where("geometries.geom IS NOT NULL AND ST_Within(ST_SetSRID(ST_MakePoint(?, ?), 4326), geometries.geom)", longitude.to_f, latitude.to_f)
  }

  scope :closest_to, -> (latitude, longitude) {
    order("geometries.lonlat <-> ST_SetSRID(ST_MakePoint(#{Arel.sql(longitude.to_f.to_s)}, #{Arel.sql(latitude.to_f.to_s)}), 4326)")
  }

  def self.geo_factory
    @geo_factory ||= RGeo::Geographic.spherical_factory(srid: 4326, uses_lenient_assertions: true)
  end

  def set_cached_name
    self.cached_name = self.name
  end

  GEOMETRY_CONTAINERS.each do |geometry, klass|
    define_method geometry do
      klass.select(:cached_name).find_by(reference: properties["wof:hierarchy"]&.first.try(:[], "#{geometry}_id"))
    end
  end

  def name
    extract_most_seen [
      "wof:name"
    ]
  end

  def self.best_match(latitude, longitude)
    locality_within = self.select(:cached_name, :cached_hierarchy, :reference).find_by_latitude_and_longitude(latitude, longitude).limit(1).first

    if locality_within.present?
      locality_within
    else
      self.select(:cached_name, :cached_hierarchy, :reference).closest_to(latitude, longitude).limit(1).first
    end
  end

  protected

  def extract_most_seen(property_keys)
    property_keys.map do |property_key|
      extract_value(property_key)
    end.compact.each_with_object(Hash.new(0)) do |value, frequency|
      frequency[value] += 1
    end.to_a.max_by(&:last).try(:[], 0)
  end

  def extract_value(property_key)
    value =
      if property_key.kind_of?(Proc)
        property_key.call
      else
        properties[property_key]
      end

    if value.present? && (value.kind_of?(Numeric) || value.to_s.length > 1)
      value
    else
      nil
    end
  end
end
