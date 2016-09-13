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
require 'rest_client'

class OptimizerWrapper

  attr_accessor :cache, :url, :api_key

  def initialize(cache, url, api_key)
    @cache, @url, @api_key = cache, url, api_key
  end

  # positions with stores at the end
  # services Array[Hash{start1: , end1: , duration: , stop_id: , vehicle_id: , quantities: []}]
  # vehicles Array[Hash{id: , open: , close: , stores: [], rests: [], capacities: []}]
  def optimize(positions, services, vehicles, options, &matrix_progress)
    key = Digest::MD5.hexdigest(Marshal.dump([positions, services, vehicles, options]))

    result = @cache.read(key)
    if !result
      stores = vehicles.flat_map{ |v| v[:stores] }
      rests = vehicles.flat_map{ |v| v[:rests] }
      shift_stores = 0

      vrp = {
        units: vehicles[0][:capacities].each_with_index.collect{ |c, i|
          {id: c["capacity1_#{i+1}_unit".to_sym] || "unit#{i+1}"}
        },
        points: positions.each_with_index.collect{ |pos, i|
          {
            id: "p#{i}",
            location: {
              lat: pos[0],
              lon: pos[1]
            }
          }
        },
        rests: rests.collect{ |rest|
          {
            id: "r#{rest[:stop_id]}",
            timewindows: [{
              start: rest[:start1],
              end: rest[:end1]
            }],
            duration: rest[:duration]
          }
        },
        vehicles: vehicles.collect{ |vehicle|
          v = {
            id: "v#{vehicle[:id]}",
            router_mode: vehicle[:router].mode,
            router_dimension: vehicle[:router_dimension],
            speed_multiplier: vehicle[:speed_multiplier],
            # speed_multiplier_areas: vehicle[:speed_multiplier_areas],
            timewindow: {start: vehicle[:open], end: vehicle[:close]},
            start_point_id: vehicle[:stores].include?(:start) ? "p#{shift_stores + services.size}" : nil,
            end_point_id: vehicle[:stores].include?(:stop) ? "p#{1 + shift_stores + services.size}" : nil,
            cost_fixed: 0,
            cost_distance_multiplier: vehicle[:router_dimension] == 'distance' ? 1 : 0,
            cost_time_multiplier: vehicle[:router_dimension] == 'time' ? 1 : 0,
            cost_waiting_time_multiplier: vehicle[:router_dimension] == 'time' ? 1 : 0,
            cost_late_multiplier: (vehicle[:router_dimension] == 'time' && options[:soft_upper_bound] && options[:soft_upper_bound] > 0) ? options[:soft_upper_bound] : nil,
            rest_ids: vehicle[:rests].collect{ |rest|
              "r#{rest[:stop_id]}"
            },
            capacities: vehicle[:capacities].each_with_index.map{ |c, i|
              c["capacity1_#{i+1}".to_sym] ? {unit_id: c["capacity1_#{i+1}_unit".to_sym] || "unit#{i+1}", limit: c["capacity1_#{i+1}".to_sym]} : nil
            }.compact
          }
          shift_stores += vehicle[:stores].size
          v
        },
        services: services.each_with_index.collect{ |service, index|
          {
            id: "s#{service[:stop_id]}",
            type: 'service',
            sticky_vehicle_ids: service[:vehicle_id] ? ["v#{service[:vehicle_id]}"] : nil, # to force an activity on a vehicle (for instance geoloc rests)
            activity: {
              point_id: "p#{index}",
              timewindows: [
                (service[:start1] || service[:end1]) && {
                  start: service[:start1],
                  end: service[:end1]
                },
                (service[:start2] || service[:end2]) && {
                  start: service[:start2],
                  end: service[:end2]
                },
              ].compact,
              duration: service[:duration]
            },
            quantities: service[:quantities].each_with_index.map{ |q, i|
              (q["quantity1_#{i+1}".to_sym] || i == 0) ? {unit_id: vehicles[0][:capacities][i]["capacity1_#{i+1}_unit".to_sym] || "unit#{i+1}", value: q["quantity1_#{i+1}".to_sym] || 1} : nil
            }.compact
          }.delete_if{ |k, v| !v }
        },
        configuration: {
          preprocessing: {
            cluster_threshold: options[:cluster_threshold],
            prefer_short_segment: true
          },
          resolution: {
            duration: options[:optimize_time] || 3600 * 1000,
            iterations_without_improvment: 100,
            initial_time_out: 3000,
            time_out_multiplier: 2
          }
        }
      }

      resource_vrp = RestClient::Resource.new(@url + '/vrp/submit.json')
      json = resource_vrp.post({api_key: @api_key, vrp: vrp}.to_json, content_type: :json, accept: :json)

      result = nil
      while json
        result = JSON.parse(json)
        # TODO: matrix_progress.call(computed, count) if matrix_progress
        if result['job']['status'] == 'completed'
          @cache.write(key, json && String.new(json)) # String.new workaround waiting for RestClient 2.0
          break
        elsif ['queued', 'working'].include?(result['job']['status'])
          sleep(2)
          job_id = result['job']['id']
          json = RestClient.get(@url + "/vrp/jobs/#{job_id}.json", params: {api_key: @api_key})
        else
          raise RuntimeError.new(result['job']['avancement'] || 'Optimizer return unknow error')
        end
      end
    else
      result = JSON.parse(result)
    end

    [result['solutions'][0]['unassigned'] ? result['solutions'][0]['unassigned'].collect{ |activity|
      activity['service_id'][1..-1].to_i
    } : []] + vehicles.collect{ |vehicle|
      route = result['solutions'][0]['routes'].find{ |r| r['vehicle_id'] == "v#{vehicle[:id]}" }
      !route ? [] : route['activities'].collect{ |activity|
        if activity.key?('service_id')
          activity['service_id'][1..-1].to_i
        elsif activity.key?('rest_id')
          activity['rest_id'][1..-1].to_i
        end
      }.compact # stores are not returned anymore
    }
  end
end
