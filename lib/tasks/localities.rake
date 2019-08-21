require 'csv'

namespace :localities do
  task import_wof: :environment do
    {
      Country => "https://geogeo-data.s3-eu-west-1.amazonaws.com/whosonfirst-data-country-latest.tar.bz2",
#      Locality => "https://geogeo-data.s3-eu-west-1.amazonaws.com/whosonfirst-data-locality-1541017474.tar.bz2"
    }.each do |model, url|
      Dir.mktmpdir do |wdir|
        puts "Download locality information"
        #      system("curl -s https://dist.whosonfirst.org/bundles/whosonfirst-data-locality-1541017474.tar.bz2 -o #{wdir}/localities.tar.bz2")
        system("curl -s #{url} -o #{wdir}/localities.tar.bz2")
        
        puts "Extract to #{wdir}"
        system("cd #{wdir} && bzip2 -d #{wdir}/localities.tar.bz2 && tar -xvf #{wdir}/localities.tar")

        csv_path = Dir["#{wdir}/**/*.csv"].first
        
        csv = CSV.new(File.open(csv_path), { :headers => true, :header_converters => :symbol, :converters => :all })
        while line = csv.shift
          locality_info = JSON.parse(File.read(File.dirname(csv_path) + "/data/" + line[:path]))
          
          factory = Locality.geo_factory
          
          def build_polygon(factory, outer_polygon, inner_polygons)
            outer_polygon_points = outer_polygon.map { |lonlat| factory.point(*lonlat) }
            inner_polygons_points = inner_polygons.map do |polygon|
              polygon.map { |lonlat| factory.point(*lonlat) }
            end
            
            factory.polygon(
              factory.linear_ring(outer_polygon_points),
              inner_polygons_points.map { |points| factory.linear_ring(points) }
            )
          end
          
          geometry =
            if locality_info["geometry"]["type"] == "Polygon"
              factory.multi_polygon(
                [
                  build_polygon(factory, locality_info["geometry"]["coordinates"].first, locality_info["geometry"]["coordinates"][1..-1])
                ]
              )
            elsif locality_info["geometry"]["type"] == "MultiPolygon"
              factory.multi_polygon(
                locality_info["geometry"]["coordinates"].map do |polygons|
                  build_polygon(factory, polygons.first, polygons[1..-1])
                end
              )
            else
              nil
            end
          
          model.find_or_create_by(reference: locality_info["id"]) do |locality|
            locality.properties = locality_info["properties"]
            locality.lonlat = factory.point(locality_info["properties"]["geom:longitude"], locality_info["properties"]["geom:latitude"])
            locality.geom = geometry
          end
        end
      end
    end
  end
end
