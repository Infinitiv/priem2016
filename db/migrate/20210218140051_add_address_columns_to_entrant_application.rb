class AddAddressColumnsToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :address_suggestions, :json
    add_column :entrant_applications, :region_iso_code, :string
    add_column :entrant_applications, :region_with_type, :string
    add_column :entrant_applications, :geo_lat, :string
    add_column :entrant_applications, :geo_lon, :string
    add_column :entrant_applications, :verified_address, :string
  end
end
