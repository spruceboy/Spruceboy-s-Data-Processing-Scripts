#!/usr/bin/env ruby
require "trollop"
require "yaml"
require "pp"


## Command line parsing action..
#
parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
  This util spits out a layer config for mapserver

Usage:
     mapserver_layer_maker.rb [options] <file1> 
where [options] is:
EOS

  opt :name, "Name of the layer - should be sort and no spaces or other funny chars.", :type => String, :default=> "XXXXX"
  opt :group, "Name of the group - should be sort and no spaces or other funny chars.", :type => String
  opt :abstract, "Abstract for the layers", :type => String, :default => "XX fill me out XX"
  opt :title, "Title",  :type => String, :default => "XX fill me out XX"
  opt :nodata, "Nodata value.", :default => "0 0 0"
  opt :tindex, "Use tile index rather than data", :default => false
end

opts = Trollop::with_standard_exception_handling(parser) do
  o = parser.parse ARGV
  raise Trollop::HelpNeeded if ARGV.length == 0 # show help screen
  o
end



info = YAML.load(`gdal_list_corners #{ARGV.first}`)

config = []

config << "LAYER"
config << "\t name #{opts[:name]}"
config << "\t type raster"
config << "\t status on"
config << "\t OFFSITE #{opts[:nodata]}"

if ( opts[:tindex])
	config << "\t TILEINDEX \"#{ARGV.first}\""
else
	config << "\t DATA \"#{ARGV.first}\""
end


#projection info
config << "\t PROJECTION"
info["s_srs"].split("+").compact.each do |x|
	x.strip!
	next if x == ""
	config << "\t\t\"#{x}\""
end
config << "\t END"

config << "\t# set if needed.. values need to be calcuated carefully.."
config << "\t# MINSCALE 20000"
config << "\t# MAXSCALE 5000000"
config << "\t GROUP \"#{opts[:group]}\"" if opts[:group]
config << "\t METADATA"
config << "\t\t WMS_TITLE \"#{opts[:title]}\""
config << "\t\t WMS_ABSTRACT \"#{opts[:abstract]}\""
config << "\t\t \"wms_group_title\"      \"#{opts[:group]}\"" if opts[:group]
config << "\t\t \"wms_extent\" \"#{info["geometry_en"]["upper_left_east"]} #{info["geometry_en"]["lower_left_north"]} #{info["geometry_en"]["lower_right_east"]} #{info["geometry_en"]["upper_left_north"]}\""
config << "\t END"
config << "END"



puts config.join("\n")
