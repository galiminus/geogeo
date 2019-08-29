class Locality < Geometry
  validates :reference, presence: true
  validates :properties, presence: true
  validates :lonlat, presence: true
  validates :name, presence: true

  before_save :set_cached_hierarchy

  def set_cached_hierarchy
    self.cached_hierarchy = [country&.cached_name, region&.cached_name]
  end
  
  def as_json(options = {})
    {
      name: cached_name,
      region: cached_hierarchy[1],
      country: cached_hierarchy[0],
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

  def self.best_match(latitude, longitude)
    locality_within = Locality.select(:cached_name, :cached_hierarchy).find_by_latitude_and_longitude(latitude, longitude).limit(1).first

    if locality_within.present?
      locality_within
    else
      Locality.select(:cached_name, :cached_hierarchy).closest_to(latitude, longitude).limit(1).first
    end
  end
end
