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
class V01::Tags < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def tag_params
      p = ActionController::Parameters.new(params)
      p = p[:tag] if p.key?(:tag)
      p.permit(:label)
    end
  end

  resource :tags do
    desc 'Fetch customer\'s tags.', {
      nickname: 'getTags',
      is_array: true,
      entity: V01::Entities::Tag
    }
    get do
      present current_customer.tags.load, with: V01::Entities::Tag
    end

    desc 'Fetch tag.', {
      nickname: 'getTag',
      entity: V01::Entities::Tag
    }
    params {
      requires :id, type: Integer
    }
    get ':id' do
      present current_customer.tags.find(params[:id]), with: V01::Entities::Tag
    end

    desc 'Create tag.', {
      nickname: 'createTag',
      params: V01::Entities::Tag.documentation.except(:id).merge({
        label: { required: true }
      }),
      entity: V01::Entities::Tag
    }
    post do
      tag = current_customer.tags.build(tag_params)
      tag.save!
      present tag, with: V01::Entities::Tag
    end

    desc 'Update tag.', {
      nickname: 'updateTag',
      params: V01::Entities::Tag.documentation.except(:id),
      entity: V01::Entities::Tag
    }
    params {
      requires :id, type: Integer
    }
    put ':id' do
      tag = current_customer.tags.find(params[:id])
      tag.update(tag_params)
      tag.save!
      present tag, with: V01::Entities::Tag
    end

    desc 'Delete tag.', {
      nickname: 'deleteTag'
    }
    params {
      requires :id, type: Integer
    }
    delete ':id' do
      current_customer.tags.find(params[:id]).destroy
    end

    desc 'Delete multiple tags.', {
      nickname: 'deleteTags'
    }
    params {
      requires :ids, type: Array[Integer]
    }
    delete do
      Tag.transaction do
        ids = params[:ids].collect(&:to_i)
        current_customer.tags.select{ |tag| ids.include?(tag.id) }.each(&:destroy)
      end
    end
  end
end
