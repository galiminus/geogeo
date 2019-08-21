class Country < Geometry
  def name
    extract_most_seen [
      "wof:name",
      -> { properties['name:eng_x_preferred'].try(:[], 0) }
    ]
  end
end
