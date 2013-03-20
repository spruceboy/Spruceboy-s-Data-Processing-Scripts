#!/usr/bin/env ruby
require "trollop"
require "fileutils"
#############
# Simple command to run several things at once
# ./make_pan_viirs.rb -h is your friend/fiend


#wrapper for system - runs command on task
def runner ( command, opts)
  puts("Info: Running: #{command}") if (opts[:verbrose])
  start_time = Time.now
  system(command)
  puts("Info: Done in #{(Time.now - start_time)/60.0}m.") if (opts[:verbrose])
end

def get_band (color, area )
  pattern = "*.#{area}.band_#{color}.tif"
  puts ("Info:(get_band)Looking for #{pattern}")
  #.alaska_albers.band_12.tif
  band = Dir.glob(pattern)
  raise(RuntimeError, "Too many bands found ({band.join(",")} for band #{color}") if (band.length > 1)
  raise(RuntimeError,"No bands found for band #{color}") if (band.length == 0)
  band.first
end


## Command line parsing action..
parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
  This util makes a "nighttime" modis band image. Needs tweeks.

Usage: 
	make_modis_natural_color.rb [options] <modis dir> 
where [options] is:
EOS

  opt :area, "Area to be used", :default => "alaska_albers"
  opt :band, "band", :default =>  "23"
  opt :stretch, "Stretch to be used, be sure to quote!", :default => "-percentile-range 0.02 0.98"
end

opts = Trollop::with_standard_exception_handling(parser) do
  o = parser.parse ARGV
  raise Trollop::HelpNeeded if ARGV.length != 1 # show help screen
  o
end

contrast_options = "-ndv '32767' -ndv 65535 -ndv 0.0 -linear-stretch #{opts[:stretch]} -outndv 0 "
contrast_options = "-valid-range '0..32760' #{opts[:stretch]} -outndv 0 "
gdal_opts = "-co TILED=YES -co COMPRESS=LZW -a_nodata \"0 0 0\" "

FileUtils.cd(ARGV[0]) do
  tmp_name = "night_" + opts[:area]+ ".tmp"
  band = get_band(opts[:band], opts[:area])
  runner("gdal_contrast_stretch #{contrast_options} #{band} #{tmp_name}.tif", opts)
  final_file =  File.basename(get_band(opts[:band], opts[:area])).split(".")[0,3].join(".")
  final_file += "_" + opts[:band]
  final_file += "." + opts[:area]
  runner("gdal_translate #{gdal_opts} #{tmp_name}.tif #{final_file}.tif ", opts)
  runner("add_overviews.rb #{final_file}.tif ", opts)
  runner("rm -v #{tmp_name}.tif", opts)
  runner("gdal_translate -of png -outsize 1000 1000 #{final_file}.tif #{final_file}.small.png", opts)
end
