require "brittany_ferries/version"

module BrittanyFerries
end

require "bundler/setup"

require "mechanize"
require "tidy_ffi"
require "active_support"

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

def price(origin, destination, out_departing_at, out_arriving_at, in_departing_at, in_arriving_at)
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
      form.radiobutton_with(name: "frmOSailing", value: "2012-04-11T09:00:00").check # departure time
      form["frmORoute"] = "PH" # Portsmouth-Cherbourg
      form["frmOSailingArrive"] = "2012-04-11T13:00:00" # arrival time

      form.radiobutton_with(name: "frmISailing", value: "2012-04-16T17:00:00").check # departure time
      form["frmIRoute"] = "HP" # Cherbourg-Portsmouth
      form["frmISailingArrive"] = "2012-04-16T19:00:00" # arrival time
    end.submit
    page_four = page_three.form_with(name: "booking").submit
    gross_price = (page_four.doc/".grossprice").first.inner_text
  end
  return gross_price
end

#File.open("temp.html", "w") { |f| f.write(TidyFFI::Tidy.new(page_four.parser.to_html).clean) }

# p price("Portsmouth / Poole", "Cherbourg")

