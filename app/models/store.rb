# Copyright © Mapotempo, 2014
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'geocode'

class Store < ActiveRecord::Base
  belongs_to :customer
  has_many :vehicle_starts, class_name: 'Vehicle', inverse_of: :store_start, foreign_key: 'store_start_id'
  has_many :vehicle_stops, class_name: 'Vehicle', inverse_of: :store_stop, foreign_key: 'store_stop_id'
  has_many :vehicle_rests, class_name: 'Vehicle', inverse_of: :store_rest, foreign_key: 'store_rest_id', dependent: :nullify

  nilify_blanks
  auto_strip_attributes :name, :street, :postalcode, :city
  validates :customer, presence: true
  validates :name, presence: true
#  validates :street, presence: true
  validates :city, presence: true
  validates :lat, numericality: {only_float: true}
  validates :lng, numericality: {only_float: true}

  before_update :update_geocode
  before_save :update_out_of_date
  before_destroy :destroy_vehicle_store

  def geocode
    address = Geocode.code(street, postalcode, city)
    Rails.logger.info address
    if address
      self.lat, self.lng = address[:lat], address[:lng]
    end
    @is_gecoded = true
  end

  def distance(position)
    lat && lng && position.lat && position.lng && Math.hypot(position.lat - lat, position.lng - lng)
  end

  def destroy
    out_of_date # Too late to do this in before_destroy callback, children already destroyed
    super
  end

  private

  def vehicles
    (vehicle_starts.to_a + vehicle_stops.to_a).uniq
  end

  def update_out_of_date
    if lat_changed? || lng_changed? || open_changed? || close_changed?
      out_of_date
    end
  end

  def update_geocode
    if !@is_gecoded && (street_changed? || postalcode_changed? || city_changed?)
      geocode
    end
  end

  def out_of_date
    Route.transaction do
      vehicles.each{ |vehicle|
        vehicle.routes.each{ |route|
          route.out_of_date = true
          route.save
        }
      }
    end
  end

  def destroy_vehicle_store
    default = customer.stores.find{ |store| store != self && !store.destroyed? }
    if default
      vehicles.each{ |vehicle|
        vehicle.store_start = default if vehicle.store_start = self
        vehicle.store_stop = default if vehicle.store_stop = self
        vehicle.save!
      }
      true
    else
      raise I18n.t('activerecord.errors.models.stores.at_least_one')
    end
  end
end
