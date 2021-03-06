require 'test_helper'

class V01::VehiclesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @vehicle = vehicles(:vehicle_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/vehicles#{part}.json?api_key=testkey1"
  end

  test 'should return customer''s vehicles' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @vehicle.customer.vehicles.size, JSON.parse(last_response.body).size
  end

  test 'should return a vehicle' do
    get api(@vehicle.id)
    assert last_response.ok?, last_response.body
    assert_equal @vehicle.name, JSON.parse(last_response.body)['name']
  end

  test 'should update a vehicle' do
    @vehicle.name = 'new name'
    put api(@vehicle.id), @vehicle.attributes
    assert last_response.ok?, last_response.body

    get api(@vehicle.id)
    assert last_response.ok?, last_response.body
    assert_equal @vehicle.name, JSON.parse(last_response.body)['name']
  end
end
