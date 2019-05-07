# Copyright © Mapotempo, 2016
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
class V01::Devices::Teksat < Grape::API

  rescue_from DeviceServiceError do |e|
    error! e.message, 200
  end

  namespace :devices do
    namespace :teksat do
      before do
        current_customer params[:customer_id]
        Mapotempo::Application.config.devices[:teksat].authenticate @current_customer, params
        teksat_authenticate @current_customer
      end

      helpers do
        def service
          TeksatService.new customer: @current_customer, ticket_id: session[:teksat_ticket_id]
        end
      end

      desc 'List Devices.',
        detail: 'For Teksat devices.',
        nickname: 'deviceTeksatList',
        is_array: true,
        success: V01::Status.success(:code_200, V01::Entities::DeviceItem),
        failure: V01::Status.failures(is_array: true)
      get 'devices' do
        present service.list_devices, with: V01::Entities::DeviceItem
      end

      desc 'Send Planning Routes.',
        detail: 'For Teksat devices.',
        nickname: 'deviceTeksatSendMultiple',
        success: V01::Status.success(:code_201),
        failure: V01::Status.failures
      params do
        requires :planning_id, type: Integer, desc: 'Planning ID'
      end
      post 'send_multiple' do
        device_send_routes device_id: :teksat_id
      end

      desc 'Clear Route.',
        detail: 'For Teksat devices.',
        nickname: 'deviceTeksatClear',
        success: V01::Status.success(:code_204),
        failure: V01::Status.failures
      params do
        requires :route_id, type: Integer, desc: 'Route ID'
      end
      delete 'clear' do
        device_clear_route
      end

      desc 'Clear Planning Routes.',
        detail: 'For Teksat devices.',
        nickname: 'deviceTeksatClearMultiple',
        success: V01::Status.success(:code_204),
        failure: V01::Status.failures
      params do
        requires :planning_id, type: Integer, desc: 'Planning ID'
      end
      delete 'clear_multiple' do
        device_clear_routes device_id: :teksat_id
      end

      desc 'Synchronise Vehicles.',
        detail: 'For Teksat devices.',
        nickname: 'deviceTeksatSync',
        success: V01::Status.success(:code_204),
        failure: V01::Status.failures
      post 'sync' do
        teksat_sync_vehicles @current_customer, session[:teksat_ticket_id]
        status 204
      end
    end
  end
end
