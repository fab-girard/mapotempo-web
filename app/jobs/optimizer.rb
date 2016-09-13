# Copyright © Mapotempo, 2013-2015
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
require 'optim/ort'
require 'optimizer_job'

class Optimizer
  @@optimize_time = Mapotempo::Application.config.optimize_time
  @@soft_upper_bound = Mapotempo::Application.config.optimize_soft_upper_bound

  def self.optimize(planning, route, global = false, synchronous = false)
    optimize_time = planning.customer.optimization_time || @@optimize_time
    soft_upper_bound = planning.customer.optimization_soft_upper_bound || @@soft_upper_bound
    if route && route.size_active <= 1
      # Nothing to optimize
      route.compute
      planning.save
    elsif !synchronous && Mapotempo::Application.config.delayed_job_use
      if planning.customer.job_optimizer
        # Customer already run an optimization
        planning.errors.add(:base, I18n.t('errors.planning.already_optimizing'))
        false
      else
        planning.customer.job_optimizer = Delayed::Job.enqueue(OptimizerJob.new(planning.id, route && route.id, global))
        planning.customer.job_optimizer.progress = '0;0;'
        planning.customer.job_optimizer.save!
      end
    else
      routes = planning.routes.select{ |r|
        (route && r.id == route.id) || (!route && !global && r.vehicle_usage) || (!route && global)
      }.reject(&:locked)
      optimum = planning.optimize(routes, global, nil) { |matrix, services, vehicles, dimension|
        Mapotempo::Application.config.optimize.optimize(matrix, dimension, services, vehicles, {optimize_time: optimize_time ? optimize_time * 1000 : nil, soft_upper_bound: soft_upper_bound, cluster_threshold: planning.customer.optimization_cluster_size || Mapotempo::Application.config.optimize_cluster_size})
      }
      if optimum
        planning.set_stops(routes, optimum)
        routes.each{ |r|
          r.reload # Refresh stops order
          r.compute if r.vehicle_usage
          r.save!
        }
        planning.reload
        planning.save
      else
        false
      end
    end
  end
end
