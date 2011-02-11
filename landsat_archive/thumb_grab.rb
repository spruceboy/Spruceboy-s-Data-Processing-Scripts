#!/usr/bin/env ruby
#
require "pp"
require "yaml"

url_base = "http://edcsns17.cr.usgs.gov/browse/tm/"

ARGV.each do |cfg|
  items = File.open(cfg){|fd| YAML.load(fd)}
  items.each do |item|
	thumb_path =  "thumbs/"+item["entity_id"] +".jpg"
	next if (File.exists?(thumb_path))
	command = ["wget", "-O", thumb_path, url_base+item["thumb_path"]]
	puts "Running..\"#{command.join(" ")}\".."
	system(*command)
	sleep(rand(4))
  end
end


