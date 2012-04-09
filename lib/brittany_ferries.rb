require "brittany_ferries/version"

module BrittanyFerries
end

require "bundler/setup"

require "mechanize"
require "tidy_ffi"
require "active_support/time"

class NokogiriParser < Mechanize::Page
  attr_reader :doc
  def initialize(uri = nil, response = nil, body = nil, code = nil)
    @doc = Nokogiri(TidyFFI::Tidy.new(body).clean)
    super(uri, response, body, code)
  end
end

def month_number(date)
  (date.year - Time.at(0).year) * 12 + date.month - 1
end

def price(origin, destination, out_departing_at, out_arriving_at, in_departing_at, in_arriving_at, route)
  gross_price = nil
  agent = Mechanize.new
  agent.pluggable_parser.html = NokogiriParser
  agent.get("http://www.brittany-ferries.co.uk/ferry-booking-303") do |page_one|
    page_two = page_one.form_with(name: "booking") do |form|
      form.field_with(name: "frmOGroup").options.detect { |o| o.text.strip == "#{origin} to #{destination}" }.select
      form["frmOMonthYear"] = month_number(out_departing_at.to_date) # "507" - Apr 2012 (zero-based month index from Jan 1970)
      form["frmODay"] = out_departing_at.day # "11" # Wed 11
      form["frmOMonth"] = out_departing_at.month # "4" # Apr
      form["frmOYear"] = out_departing_at.year # "2012"

      form.field_with(name: "frmIGroup").options.detect { |o| o.text.strip == "#{destination} to #{origin}" }.select
      form["frmIMonthYear"] = month_number(in_departing_at.to_date) # "507" - Apr 2012 (zero-based month index from Jan 1970)
      form["frmIDay"] = in_departing_at.day # "16" # Mon 16
      form["frmIMonth"] = in_departing_at.month # "4" # Apr
      form["frmIYear"] = in_departing_at.year # "2012"

      form.field_with(name: "frmOTowingorBv").options.detect { |o| o.text.strip == "Car" }.select
      form["frmOTowingLength"] = "500" # 5.00m
      form["frmOTowingHeight"] = "183" # 1.83m
      form["frmPassengerAo"] = "2" # 2 adults

      form.field_with(name: "frmITowingorBv").options.detect { |o| o.text.strip == "Car" }.select
      form["frmITowingLength"] = "500" # 5.00m
      form["frmITowingHeight"] = "183" # 1.83m
      form["frmPassengerAi"] = "2" # 2 adults
    end.submit
    page_three = page_two.form_with(name: "booking") do |form|
      form.radiobutton_with(name: "frmOSailing", value: out_departing_at.iso8601.slice(0..-7)).check
      form["frmORoute"] = route
      form["frmOSailingArrive"] = out_arriving_at.iso8601.slice(0..-7)

      form.radiobutton_with(name: "frmISailing", value: in_departing_at.iso8601.slice(0..-7)).check
      form["frmIRoute"] = route.reverse
      form["frmISailingArrive"] = in_arriving_at.iso8601.slice(0..-7)
    end.submit
    page_four = page_three.form_with(name: "booking") do |form|
      if out_arriving_at.to_date > out_departing_at.to_date
        form["frmOaccomRS"] = "2"
      end
      if in_arriving_at.to_date > in_departing_at.to_date
        form["frmIaccomRS"] = "2"
      end
    end.submit
    gross_price = (page_four.doc/".grossprice").first.inner_text
  end
  return gross_price
rescue => e
  p e
  File.open("error.html", "w") { |f| f.write(TidyFFI::Tidy.new(agent.current_page.parser.to_html).clean) }
end

Time.zone = "London"

origin, destination, route = "Portsmouth / Poole", "Cherbourg", "PH"

outbounds = [
  ["2012-04-11 09:00:00", "2012-04-11 13:00:00"],
  ["2012-04-12 09:00:00", "2012-04-12 13:00:00"],
  ["2012-04-13 09:00:00", "2012-04-13 13:00:00"],
  ["2012-04-14 09:00:00", "2012-04-14 13:00:00"],
]

inbounds = [
  ["2012-04-13 17:00:00", "2012-04-13 19:00:00"],
  ["2012-04-14 17:00:00", "2012-04-14 19:00:00"],
  ["2012-04-15 17:00:00", "2012-04-15 19:00:00"],
  ["2012-04-16 17:00:00", "2012-04-16 19:00:00"],
]


origin, destination, route = "Portsmouth", "Caen", "PN"

outbounds = [
  ["2012-04-11 10:00", "2012-04-11 17:00"],
  ["2012-04-11 22:00", "2012-04-12 06:45"],

  ["2012-04-12 08:15", "2012-04-12 15:00"],
  ["2012-04-12 14:45", "2012-04-12 21:30"],
  ["2012-04-12 22:45", "2012-04-13 06:45"],

  ["2012-04-13 08:15", "2012-04-13 15:00"],
  ["2012-04-13 14:45", "2012-04-13 21:30"],
  ["2012-04-13 22:45", "2012-04-14 06:45"],

  ["2012-04-14 08:15", "2012-04-14 15:00"],
  ["2012-04-14 14:45", "2012-04-14 21:30"],
  ["2012-04-14 22:45", "2012-04-15 06:45"],
]

inbounds = [
  ["2012-04-14 08:30", "2012-04-14 13:15"],
  ["2012-04-14 16:30", "2012-04-14 21:15"],
  ["2012-04-14 23:00", "2012-04-15 06:30"],

  ["2012-04-15 08:30", "2012-04-15 13:15"],
  ["2012-04-15 17:30", "2012-04-15 22:15"],
  ["2012-04-15 23:00", "2012-04-16 06:30"],

  ["2012-04-16 08:45", "2012-04-16 13:15"],
  ["2012-04-16 16:30", "2012-04-16 21:15"],
  ["2012-04-16 23:00", "2012-04-17 06:30"],

  ["2012-04-17 08:30", "2012-04-17 13:15"],
  ["2012-04-17 16:30", "2012-04-17 21:15"],
  ["2012-04-17 23:00", "2012-04-18 06:30"],
]

outbounds.each do |outbound|
  inbound = inbounds.each do |inbound|
    price = price(origin, destination, Time.zone.parse(outbound.first), Time.zone.parse(outbound.last), Time.zone.parse(inbound.first), Time.zone.parse(inbound.last), route)
    puts "#{outbound.first}-#{outbound.last} #{inbound.first}-#{inbound.last} #{price}"
  end
end
