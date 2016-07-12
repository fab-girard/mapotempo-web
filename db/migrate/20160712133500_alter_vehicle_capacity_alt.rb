class AlterVehicleCapacityAlt < ActiveRecord::Migration
  def change
    add_column :vehicles, :capacity_alt, :integer
    add_column :vehicles, :capacity_unit_alt, :string
    add_column :visits, :quantity_alt, :float
  end
end
