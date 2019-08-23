class Geometry < ApplicationRecord
  scope :find_by_latitude_and_longitude, -> (latitude, longitude) {
    where("geometries.geom IS NOT NULL AND ST_Within(ST_SetSRID(ST_MakePoint(?, ?), 4326), geometries.geom)", longitude.to_f, latitude.to_f)
  }

  scope :closest_to, -> (latitude, longitude) {
    order("geometries.lonlat <-> ST_SetSRID(ST_MakePoint(#{Arel.sql(longitude.to_f.to_s)}, #{Arel.sql(latitude.to_f.to_s)}), 4326)")
  }
  
  def self.geo_factory
    @geo_factory ||= RGeo::Geographic.spherical_factory(srid: 4326, uses_lenient_assertions: true)
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
