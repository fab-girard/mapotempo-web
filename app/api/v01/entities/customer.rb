# Copyright © Mapotempo, 2014-2015
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
class V01::Entities::Customer < Grape::Entity
  def self.entity_name
    'V01_Customer'
  end

  expose(:id, documentation: { type: Integer })
  expose(:end_subscription, documentation: { type: Date })
  expose(:max_vehicles, documentation: { type: Integer })
  expose(:take_over, documentation: { type: DateTime }) { |m| m.take_over && m.take_over.strftime('%H:%M:%S') }
  expose(:store_ids, documentation: { type: Integer, is_array: true })
  expose(:job_geocoding_id, documentation: { type: Integer })
  expose(:job_optimizer_id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:tomtom_user, documentation: { type: String })
  expose(:tomtom_password, documentation: { type: String })
  expose(:tomtom_account, documentation: { type: String })
  expose(:masternaut_user, documentation: { type: String })
  expose(:masternaut_password, documentation: { type: String })
  expose(:router_id, documentation: { type: Integer })
  expose(:speed_multiplicator, documentation: { type: Float })
  expose(:default_country, documentation: { type: String })
  expose(:print_planning_annotating, documentation: { type: Integer })
  expose(:print_header, documentation: { type: String })
  expose(:alyacom_association, documentation: { type: String })
  # hidden admin only field :enable_orders, :enable_tomtom, :enable_masternaut, :enable_alyacom, :test, :optimization_cluster_size, :optimization_time, :optimization_soft_upper_bound, :profile_id
end
