require 'test_helper'

class StoreTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Store.new
    assert_not o.save, "Saved without required fields"
  end

  test "should save" do
    o = customers(:customer_one).stores.build(name: "plop", city: "Bordeaux", lat: 1, lng: 1)
    assert o.save
  end

  test "should destroy" do
    o = customers(:customer_one)
    assert_equal 2, o.stores.size
    assert o.stores[1].destroy
    o.reload
    assert_equal 1, o.stores.size
    assert_equal stores(:store_one), vehicles(:vehicle_one).store_start
  end

  test "should destroy in unse" do
    o = customers(:customer_one)
    assert_equal 2, o.stores.size
    assert o.stores[0].destroy
    o.reload
    assert_equal 1, o.stores.size
    assert_equal stores(:store_one_bis), vehicles(:vehicle_one).store_start
  end

  test "should not desroy" do
    o = customers(:customer_one)
    assert_equal 2, o.stores.size
    assert o.stores[0].destroy
    o.reload
    begin
      o.stores[0].destroy
      assert false
    rescue
      assert true
    end
  end

  test "should out_of_date" do
    o = stores(:store_one)
    assert_not o.customer.plannings[0].out_of_date
    o.lat = 10.1
    o.save!
    o.reload
    assert o.customer.plannings[0].out_of_date
  end

  test "should geocode" do
    o = stores(:store_one)
    lat, lng = o.lat, o.lng
    o.geocode
    assert o.lat
    assert_not_equal lat, o.lat
    assert o.lng
    assert_not_equal lng, o.lng
  end

  test "should update_geocode" do
    o = stores(:store_one)
    o.city = "Toulouse"
    lat, lng = o.lat, o.lng
    o.save!
    assert o.lat
    assert_not_equal lat, o.lat
    assert o.lng
    assert_not_equal lng, o.lng
  end

  test "should distance" do
    o = stores(:store_one)
    assert_equal 2.51647173560523, o.distance(stores(:store_two))
  end
end
