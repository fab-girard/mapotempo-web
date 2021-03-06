require 'test_helper'

class PlanningTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    def Osrm.compute(url, from_lat, from_lng, to_lat, to_lng)
      [1, 1, "trace"]
    end
  end

  test "should not save" do
    o = Planning.new
    assert_not o.save, "Saved without required fields"
  end

  test "should save" do
    o = customers(:customer_one).plannings.build(name: "plop", zoning: zonings(:zoning_one))
    o.default_routes
    o.save!
  end

  test "should dup" do
    o = plannings(:planning_one)
    oo = o.amoeba_dup

    assert_equal oo, oo.routes[0].planning
    oo.save!
  end

  test "should set_destinations" do
    o = plannings(:planning_one)

    o.set_destinations({'route_one' => [[destinations(:destination_one)]]})
    assert o.routes[1].stops.select{ |stop| stop.is_a?(StopDestination) }.collect(&:destination).include?(destinations(:destination_one))
    o.save!
  end

  test "should not set_destinations for tags" do
    o = plannings(:planning_one)
    o.tags << tags(:tag_two)

    o.set_destinations({'route_one' => [[destinations(:destination_one)]]})
    assert_not o.routes[1].stops.select{ |stop| stop.is_a?(StopDestination) }.collect(&:destination).include?(destinations(:destination_one))
    o.save!
  end

  test "should not set_destinations for size" do
    o = plannings(:planning_one)

    assert_raises(RuntimeError) {
      o.set_destinations(Hash[0.upto(o.routes.size).collect{ |i| ["route#{i}", [destinations(:destination_one)]] }])
    }
    o.save!
  end

  test "should vehicle_add" do
    o = plannings(:planning_one)
    assert_difference('Stop.count', 1) do # One StopRest
      assert_difference('Route.count', 1) do
        o.vehicle_add(vehicles(:vehicle_two))
        o.save!
      end
    end
  end

  test "should vehicle_remove" do
    o = plannings(:planning_one)
    assert_difference('Stop.count', -1) do
      assert_difference('Route.count', -1) do
        o.vehicle_remove(vehicles(:vehicle_one))
        o.save!
      end
    end
  end

  test "should destination_add" do
    o = plannings(:planning_one)
    assert_difference('Stop.count') do
      o.destination_add(destinations(:destination_two))
      o.save!
    end
  end

  test "should destination_remove" do
    o = plannings(:planning_one)
    assert_difference('Stop.count', -1) do
      o.destination_remove(destinations(:destination_one))
      o.save!
    end
  end

  test "should compute" do
    o = plannings(:planning_one)
    o.zoning_out_of_date = true
    o.compute
    o.routes.select{ |r| r.vehicle }.each{ |r|
      assert_not r.out_of_date
    }
    assert_not o.zoning_out_of_date
    o.save!
  end

  test "should compute with non geocoded" do
    o = plannings(:planning_one)
    o.zoning_out_of_date = true
    d0 = o.routes[0].stops[0].destination
    d0.lat = d0.lng = nil
    o.compute
    o.routes.select{ |r| r.vehicle }.each{ |r|
      assert_not r.out_of_date
    }
    assert_not o.zoning_out_of_date
  end

  test "should out_of_date" do
    o = plannings(:planning_one)
    assert_not o.out_of_date

    o.routes[1].out_of_date = true
    assert o.out_of_date
  end

  test "should update zoning" do
    o = plannings(:planning_one)
    assert_not o.zoning_out_of_date
    o.zoning = zonings(:zoning_two)
    o.save!
    assert_not o.out_of_date
  end

  test "should automatic insert" do
    o = plannings(:planning_one)
    o.zoning = nil
    assert_equal 2, o.routes.size
    assert_equal 1, o.routes[0].stops.size
    assert_equal 4, o.routes[1].stops.size
    assert_difference('Stop.count', 0) do
      o.automatic_insert(o.routes[0].stops[0])
      o.save!
      o.customer.save!
    end
    o.reload
    assert_equal 2, o.routes.size
    assert_equal 0, o.routes[0].stops.size
    assert_equal 5, o.routes[1].stops.size
  end

  test "should apply orders" do
    o = plannings(:planning_one)
    assert o.routes[1].stops[0].active
    assert o.routes[1].stops[1].active

    oa = order_arrays(:order_array_one)
    o.apply_orders(oa, 0)
    assert o.routes[1].stops[0].active
    assert_not o.routes[1].stops[1].active
    o.save!
  end

  test "should apply orders and destroy" do
    o = plannings(:planning_one)
    oa = order_arrays(:order_array_one)
    o.apply_orders(oa, 0)
    o.save!
    oa.destroy
    o.save!
  end
end
