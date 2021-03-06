# Copyright © Mapotempo, 2013-2014
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
class Tag < ActiveRecord::Base
  belongs_to :customer
  has_and_belongs_to_many :destinations
  has_and_belongs_to_many :plannings

  def self.icons_table
    ['square', 'diamon', 'star']
  end

  nilify_blanks
  auto_strip_attributes :label
  validates :label, presence: true
  validates_format_of :color, with: /\A(|\#[A-Fa-f0-9]{6})\Z/, allow_nil: true
  validates_inclusion_of :icon, in: [''] + icons_table, allow_nil: true
end
