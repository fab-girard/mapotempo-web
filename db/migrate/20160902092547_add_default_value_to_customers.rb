class AddDefaultValueToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :capacity_1, :integer
    add_column :customers, :capacity_2, :integer
    add_column :customers, :unit_1, :string
    add_column :customers, :unit_2, :string
    add_column :customers, :emission, :float
    add_column :customers, :consumption, :float
  end
end
