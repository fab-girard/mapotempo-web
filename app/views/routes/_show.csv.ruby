if route.vehicle_usage && (!@params.key?(:stops) || @params[:stops].split('|').include?('stores'))
  row = {
    route: route.ref || (route.vehicle_usage && route.vehicle_usage.vehicle.name),
    vehicle: (route.vehicle_usage.vehicle.ref if route.vehicle_usage),
    order: 0,
    stop_type: I18n.t('plannings.export_file.stop_type_store'),
    active: nil,
    wait_time: nil,
    time: (l(route.start, format: :hour_minute) if route.start),
    distance: 0,
    drive_time: 0,
    out_of_window: nil,
    out_of_capacity: nil,
    out_of_drive_time: nil,

    ref: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.ref,
    name: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.name,
    street: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.street,
    detail: nil,
    postalcode: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.postalcode,
    city: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.city,
    country: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.country,
    lat: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.lat,
    lng: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.lng,
    comment: nil,
    phone_number: nil,
    tags: nil,

    ref_visit: nil,
    duration: nil,
    (route.planning.customer.enable_orders ? :orders : :quantity) => nil,
    open: nil,
    close: nil,
    tags_visit: nil
  }
  csv << @columns.map{ |c| row[c.to_sym] }
end

index = 0
route.stops.each { |stop|
  if stop.active || !@params.key?(:stops) || @params[:stops].split('|').include?(:inactive)
    row = {
      route: route.ref || (route.vehicle_usage && route.vehicle_usage.vehicle.name),
      vehicle: (route.vehicle_usage.vehicle.ref if route.vehicle_usage),
      order: (index+=1 if route.vehicle_usage),
      stop_type: stop.is_a?(StopVisit) ? I18n.t('plannings.export_file.stop_type_visit') : I18n.t('plannings.export_file.stop_type_rest'),
      active: ((stop.active ? '1' : '0') if route.vehicle_usage),
      wait_time: ("%i:%02i" % [stop.wait_time/60/60, stop.wait_time/60%60] if route.vehicle_usage && stop.wait_time),
      time: (l(stop.time, format: :hour_minute) if route.vehicle_usage && stop.time),
      distance: (stop.distance if route.vehicle_usage),
      drive_time: (stop.drive_time if route.vehicle_usage),
      out_of_window: stop.out_of_window ? 'x' : '',
      out_of_capacity: stop.out_of_capacity ? 'x' : '',
      out_of_drive_time: stop.out_of_drive_time ? 'x' : '',

      ref: stop.is_a?(StopVisit) ? stop.visit.destination.ref : stop.ref,
      name: stop.name,
      street: stop.street,
      detail: stop.detail,
      postalcode: stop.postalcode,
      city: stop.city,
      country: stop.country,
      lat: stop.lat,
      lng: stop.lng,
      comment: stop.comment,
      phone_number: stop.phone_number,
      tags: (stop.visit.destination.tags.collect(&:label).join(',') if stop.is_a?(StopVisit)),

      ref_visit: (stop.visit.ref if stop.is_a?(StopVisit)),
      duration: stop.is_a?(StopVisit) ? (stop.visit.take_over ? l(stop.visit.take_over, format: :hour_minute_second) : nil) : (route.vehicle_usage.default_rest_duration ? l(route.vehicle_usage.default_rest_duration, format: :hour_minute_second) : nil),
      (route.planning.customer.enable_orders ? :orders : :quantity) => ((route.planning.customer.enable_orders ? (stop.order && stop.order.products.length > 0 ? stop.order.products.collect(&:code).join('/') : nil) : stop.visit.quantity) if stop.is_a?(StopVisit)),
      open: (l(stop.open, format: :hour_minute) if stop.open),
      close: (l(stop.close, format: :hour_minute) if stop.close),
      tags_visit: (stop.visit.tags.collect(&:label).join(',') if stop.is_a?(StopVisit))
    }
    csv << @columns.map{ |c| row[c.to_sym] }
  end
}

if route.vehicle_usage && (!@params.key?(:stops) || @params[:stops].split('|').include?('stores'))
  row = {
    route: route.ref || (route.vehicle_usage && route.vehicle_usage.vehicle.name),
    vehicle: (route.vehicle_usage.vehicle.ref if route.vehicle_usage),
    order: index+1,
    stop_type: I18n.t('plannings.export_file.stop_type_store'),
    active: nil,
    wait_time: nil,
    time: (l(route.end, format: :hour_minute) if route.end),
    distance: route.stop_distance,
    drive_time: route.stop_drive_time,
    out_of_window: nil,
    out_of_capacity: nil,
    out_of_drive_time: route.stop_out_of_drive_time ? 'x' : '',

    ref: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.ref,
    name: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.name,
    street: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.street,
    detail: nil,
    postalcode: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.postalcode,
    city: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.city,
    country: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.country,
    lat: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.lat,
    lng: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.lng,
    comment: nil,
    phone_number: nil,
    tags: nil,

    ref_visit: nil,
    duration: nil,
    (route.planning.customer.enable_orders ? :orders : :quantity) => nil,
    open: nil,
    close: nil,
    tags_visit: nil
  }
  csv << @columns.map{ |c| row[c.to_sym] }
end
