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
require 'uri'
require 'net/http'
require 'open-uri'
require 'json'

require 'rexml/document'
include REXML

module Geocode

  @cache = Mapotempo::Application.config.geocode_cache
  @cache_reverse = Mapotempo::Application.config.geocode_reverse_cache
  @cache_complete = Mapotempo::Application.config.geocode_complete_cache
  @ign_referer = Mapotempo::Application.config.geocode_ign_referer
  @ign_key = Mapotempo::Application.config.geocode_ign_key

  def self.reverse(lat, lng)
    self.reverse_gisgraphy(lat, lng)
  end

  def self.reverse_gisgraphy(lat, lng)
    key = [lat, lng]

    result = @cache.read(key)
    if !result
      url="http://services.gisgraphy.com/street/streetsearch?format=json&lat=#{lat}&lng=#{lng}&from=1&to=1" # FIXME filtrer les types de route, mais coment ?
      Rails.logger.info "get #{url}"
      result = JSON.parse(open(url).read)
      @cache.write(key, result)
    end

    {street: result["result"][0]["name"], postal_code: "0", city: result["result"][0]["isIn"]}
  end

  def self.reverse_ign(lat, lng)
    key = [lat, lng]

    result = @cache_reverse.read(key)
    if !result
      url = URI.parse("http://gpp3-wxs.ign.fr/#{@ign_key}/geoportail/ols")
      http = Net::HTTP.new(url.host)
      request = Net::HTTP::Post.new(url.path)
      request['Referer'] = @ign_referer
      request['Content-Type'] = 'application/xml'
      request.body = "<?xml version='1.0' encoding='UTF-8'?>
<XLS
    xmlns:xls='http://www.opengis.net/xls'
    xmlns:gml='http://www.opengis.net/gml'
    xmlns='http://www.opengis.net/xls'
    xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
    version='1.2'
    xsi:schemaLocation='http://www.opengis.net/xls http://schemas.opengis.net/ols/1.2/olsAll.xsd'>
  <RequestHeader/>
  <Request requestID='1' version='1.2' methodName='GeocodeRequest'>
    <ReverseGeocodeRequest>
      <Position><gml:Point><gml:pos>#{lat} #{lng}</gml:pos></gml:Point></Position>
      <ReverseGeocodePreference>StreetAddress</ReverseGeocodePreference>
    </ReverseGeocodeRequest>
  </Request>
</XLS>"

      response = http.request(request)
      if response.code == "200"
        result = response.body # => The body (HTML, XML, blob, whatever)
        @cache.write(key, result)
      else
        Rails.logger.info request.body
        Rails.logger.info response.code
        Rails.logger.info response.body
        raise response.body
      end
    end

    doc = Document.new(result)
    root = doc.root
    pos = root.elements['Response'].elements['ReverseGeocodeResponse'].elements['Address']
    building = pos.elements['StreetAddress'].elements['Building'].
    street = pos.elements['StreetAddress'].elements['Street'].text
    place = pos.elements['Place'].elements['PostalCode'].text
    postal_code = pos.elements['PostalCode'].text

    if building && !building.empty?
      street = "#{building} #{street}"
    end
    {street: street, postal_code: postal_code, city: place}
  end

  def self.complete(lat, lng, radius, street, postalcode, city)
    key = [lat, lng, radius, street, postalcode, city]

    result = @cache_complete.read(key)
    if !result
      url = URI::HTTP.build(:host => "services.gisgraphy.com", :path => "/street/streetsearch", :query => {
        :format => "json",
        :lat => lat,
        :lng => lng,
        :from => 1,
        :to => 20,
        :radius => radius,
#        :name => "#{street}, #{postalcode} #{city}",
        :name => street,
      }.to_query)
      Rails.logger.info "get #{url}"
      result = JSON.parse(open(url).read)
      @cache_complete.write(key, result)
    end

    result["result"].collect{ |r|
      [r["name"], "0", r["isIn"]]
    }
  end

  def self.code(street, postalcode, city)
    key = [street, postalcode, city]

    result = @cache.read(key)
    if !result
      url = URI.parse("http://gpp3-wxs.ign.fr/#{@ign_key}/geoportail/ols")
      http = Net::HTTP.new(url.host)
      request = Net::HTTP::Post.new(url.path)
      request['Referer'] = @ign_referer
      request['Content-Type'] = 'application/xml'
      request.body = "<?xml version='1.0' encoding='UTF-8'?>
<XLS
    xmlns:xls='http://www.opengis.net/xls'
    xmlns:gml='http://www.opengis.net/gml'
    xmlns='http://www.opengis.net/xls'
    xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
    version='1.2'
    xsi:schemaLocation='http://www.opengis.net/xls http://schemas.opengis.net/ols/1.2/olsAll.xsd'>
  <RequestHeader/>
  <Request requestID='1' version='1.2' methodName='LocationUtilityService'>
   <GeocodeRequest returnFreeForm='false'>
     <Address countryCode=\"StreetAddress\"> <!-- FIXME IGN bug here on quote -->
       <StreetAddress>
         <Street>#{street.encode(xml: :text)}</Street>
       </StreetAddress>
       <Place type='Municipality'>#{city.encode(xml: :text)}</Place>
       <PostalCode>#{postalcode.encode(xml: :text)}</PostalCode>
     </Address>
   </GeocodeRequest>
  </Request>
</XLS>"

      response = http.request(request)
      if response.code == "200"
        result = response.body # => The body (HTML, XML, blob, whatever)
        @cache.write(key, result)
      else
        Rails.logger.info request.body
        Rails.logger.info response.code
        Rails.logger.info response.body
        raise response.body
      end
    end

    begin
      doc = Document.new(result)
      root = doc.root
      pos = root.elements['Response'].elements['GeocodeResponse'].elements['GeocodeResponseList'].elements['GeocodedAddress'].elements['gml:Point'].elements['gml:pos'].text
      pos = pos.split(' ')

      {lat: pos[0], lng: pos[1]}
    rescue Exception => e
      Rails.logger.info e
      nil
    end
  end
end
