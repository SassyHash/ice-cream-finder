
#request location
# use geocoding api to return lat & long
# feed string "ice cream" + lat & long to places api
# optional, sort by distance if provided by places
# user selects which location, we query directions api for directions (send origin/destination) return directions
require 'debugger'
require 'rest-client'
require 'json'
require 'addressable/uri'
require 'nokogiri'
GOOGLEAPIKEY = "AIzaSyDMFjLRPP-kHOQB_zeQzuubY5qOUZuCAmI"

class IceCreamFinder
  def run
    starting_address = request_user_input
    start_coordinates = get_lat_long(starting_address)
    list_of_stores = sort_by_ratings!(search_for_ice_cream(start_coordinates))
    destination = list_of_stores[select_stores(list_of_stores)][:address]
    get_directions(starting_address, destination)

  end

  def request_user_input
    puts "What is your address?"
    address = gets.chomp
  end

  def sort_by_ratings!(array_of_stores)
    array_of_stores.each {|store| store[:rating] = 0 if store[:rating] == nil}
    array_of_stores.sort_by!{|store| store[:rating]}.reverse
  end

  def select_stores(array_of_stores)
    array_of_stores.each_with_index do |store_details, index|
      puts "Store #{index+1}: #{store_details[:name]} is located at #{store_details[:address]} with a rating of #{store_details[:rating]}."
    end

    puts "Which store would you like to get directions to?"
    gets.chomp.to_i
  end

  def querystring(path, query_line)
    q = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => path,
    :query => query_line
    ).to_s
    p q
    response = JSON.parse(RestClient.get(q))
  end

  def get_lat_long(address)
    response = querystring("maps/api/geocode/json", "address=#{address.gsub(" ","+")}&sensor=false")
    [response["results"][0]["geometry"]["location"]["lat"], response["results"][0]["geometry"]["location"]["lng"]]
  end

  def search_for_ice_cream(coordinates)
    response = querystring("maps/api/place/textsearch/json","query=#{"ice cream".gsub(" ","+")}&key=#{GOOGLEAPIKEY}&sensor=false&location=#{coordinates[0]},#{coordinates[1]}&radius=500")
    array_of_stores = []
    response["results"].each do |store_info|
      store_details = {}
      store_details[:address] = store_info["formatted_address"]
      store_details[:name] = store_info["name"]
      store_details[:rating] = store_info["rating"]
      array_of_stores << store_details
    end
    array_of_stores
  end

  def get_directions(from, destination)
    response = querystring("maps/api/directions/json", "origin=#{from.gsub(" ", "+")}&destination=#{destination.gsub(" ", "+")}&sensor=false")
    response["routes"][0]["legs"][0]["steps"].each_with_index do |step, index|
      instructions = Nokogiri::HTML(step["html_instructions"]).xpath("//text().to_s")
      puts "Step #{index+1}: #{instructions} /n #{step["distance"]["text"]}"
    end
  end
end

i= IceCreamFinder.new
i.run