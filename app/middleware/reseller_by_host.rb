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
class ResellerByHost
  def initialize(app)
    puts '----> middleware / reseller_by_host::initialize'
    @app = app
    @cache = {}
  end

  def call(env)
    puts '----> middleware / reseller_by_host::call'
    env['reseller'] = reseller(env['HTTP_HOST'])
    @app.call(env)
  end

  private

  def reseller(host)
    @cache[host] ||= Reseller.where(host: host).first || Reseller.first
  end
end
