# Copyright © Mapotempo, 2015
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
require 'here'

class RouterHere < Router
  def trace(speed_multiplicator, lat1, lng1, lat2, lng2)
    distance, time, trace = Here.compute(lat1, lng1, lat2, lng2)
    time *= 1.0 / speed_multiplicator
    [distance, time, trace]
  end

  def matrix(vector, speed_multiplicator, &block)
    time_multiplicator = 1.0 / speed_multiplicator
    vector = pack_vector(vector)
    matrix = Here.matrix(vector, &block)
    matrix = matrix.collect{ |row|
      row.collect{ |distance, time|
        [distance, time * time_multiplicator]
      }
    }
    unpack_vector(vector, matrix)
  end
end
