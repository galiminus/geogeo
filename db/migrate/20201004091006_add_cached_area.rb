class AddCachedArea < ActiveRecord::Migration[6.0]
  def change
    add_column :geometries, :cached_area, :float
  end
end
