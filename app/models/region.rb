class Region < Geometry
  validates :name, presence: true
  
  before_save :set_cached_hierarchy

  def set_cached_hierarchy
    self.cached_hierarchy = [country&.cached_name]
  end

  def as_json(options = {})
    {
      name: cached_name,
      country: cached_hierarchy[0],
    }
  end
  
  def name
    extract_most_seen [
      "wof:name",
      -> { properties['name:eng_x_preferred'].try(:[], 0) }
    ]
  end
end
