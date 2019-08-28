class Country < Geometry
  validates :name, presence: true
  
  def as_json(options = {})
    {
      name: cached_name
    }
  end
  
  def name
    extract_most_seen [
      "wof:name",
      -> { properties['name:eng_x_preferred'].try(:[], 0) }
    ]
  end
end
