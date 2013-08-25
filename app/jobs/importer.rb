require 'geocoder_job'

class Importer

  def self.import(customer, file, name)
    if Opentour::Application.config.delayed_job_use and customer.job_geocoding
      return false
    end

    tags = Hash[customer.tags.collect{ |tag| [tag.label, tag] }]
    routes = Hash.new{ |h,k| h[k] = [] }

    separator = ','
    decimal = '.'
    File.open(file) do |f|
      line = f.readline
      splitComma, splitSemicolon = line.split(','), line.split(';')
      split, separator = splitComma.size() > splitSemicolon.size() ? [splitComma, ','] : [splitSemicolon, ';']

      csv = CSV.open(file, col_sep: separator, headers: true)
      row = csv.readline
      ilat = row.index('lat')
      row = csv.readline
      if ilat
        data = row[ilat]
        decimal = data.split('.').size > data.split(',').size ? '.' : ','
      end
    end

    Destination.transaction do
      delayed_job = false
      customer.destinations.destroy_all

      CSV.foreach(file, col_sep: separator, headers: true) { |row|
        r = row.to_hash.select{ |k|
          ["name", "street", "postalcode", "city", "lat", "lng"].include?(k)
        }
        if decimal == ','
          r["lat"].gsub!(',', '.')
          r["lng"].gsub!(',', '.')
        end
        destination = Destination.new(r)
        destination.customer = customer

        if row["tags"]
          destination.tags = row["tags"].split(',').collect { |key|
            if not tags.key?(key)
              customer.tags << tags[key] = Tag.new(label: key, customer: customer)
            end
            tags[key]
          }
        end

        routes[row.key?("route")? row["route"] : nil] << destination

        if not(destination.lat and destination.lng)
          if not Opentour::Application.config.delayed_job_use
            destination.geocode
          else
            delayed_job = true
          end
        end

        customer.destinations << destination
      }

      if routes.size > 1
        planning = Planning.new(name: name)
        planning.customer = customer
        planning.set_destinations(routes.values)
        customer.plannings << planning
      end

      if delayed_job
        customer.job_geocoding = Delayed::Job.enqueue(GeocoderJob.new(customer.id))
      end
    end

    return true
  end

end
