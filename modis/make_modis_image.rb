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
  puts ("Info:(get_band)Looking for *#{area}*band_#{color}.tif")
  band = Dir.glob("*#{area}*band_#{color}.tif")
  raise(RuntimeError, "Too many bands found ({green.join(",")} for band #{color}") if (band.length > 1)
  raise(RuntimeError,"No bands found for band #{color}") if (band.length == 0)
  band.first
end


## Command line parsing action..
parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
  This util makes pan banded action from viirs data from pytroll.  

Usage:
      make_modis_image.rb [options] <modis dir> 
where [options] is:
EOS

  opt :red, "red band", :default =>  "500m_CorrRefl_01"
  opt :green, "green band", :default =>  "500m_CorrRefl_04"
  opt :blue, "blue band", :default =>  "500m_CorrRefl_03"
  opt :pan, "pan band", :default => "none"
  opt :verbrose, "Maxium Verbrosity.", :short => "V"
  opt :dry_run, "Don't actually run the command(s)"
  opt :area, "Area to be used", :default => "alaska_albers"
  opt :stretch, "Stretch to be used, be sure to quote!", :default => "-percentile-range 0.02 0.98"
  opt :rename, "Rename to this extention", :type=>String
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
  tmp_name = opts[:red] + "_" + opts[:green] + "_" + opts[:blue] + "_" + opts[:area]+ ".tmp"
  red = get_band(opts[:red], opts[:area])
  green = get_band(opts[:green], opts[:area])
  blue = get_band(opts[:blue], opts[:area])
  runner("gdalbuildvrt -resolution lowest -separate #{tmp_name}.vrt #{red} #{green} #{blue}", opts)
  runner("gdal_contrast_stretch #{contrast_options} #{tmp_name}.vrt #{tmp_name}.tif", opts)

  final_file =  File.basename(get_band(opts[:red], opts[:area])).split(".")[0,3].join(".")
  temp_file = ""
  if ( opts[:pan] != "none" )
    temp_file = tmp_name + "_" + opts[:pan]
    final_file += "_" + opts[:red] + "_" + opts[:green] + "_" + opts[:blue] + "_" + opts[:pan] 
    pan = get_band(opts[:pan], opts[:area])
    runner("gdal_contrast_stretch #{contrast_options} #{pan} #{pan}.tmp", opts)
    runner("gdal_landsat_pansharp -ndv 0 -rgb #{tmp_name}.tif -pan #{pan}.tmp -o #{temp_file}.tif", opts)
    runner("rm -v #{pan}.tmp", opts)
  else
    temp_file = tmp_name 
    final_file += "_" + opts[:red] + "_" + opts[:green] + "_" + opts[:blue] 
  end

  if (opts[:rename])
        final_file = File.basename(get_band(opts[:red], opts[:area])).split(".")[0,3].join(".") + "." + opts[:rename]
  end


  final_file += "." + opts[:area]
  runner("gdal_translate #{gdal_opts} #{temp_file}.tif #{final_file}.tif ", opts)
  runner("add_overviews.rb #{final_file}.tif ", opts)
  runner("rm -v #{temp_file}.tif #{tmp_name}.vrt #{tmp_name}.tif", opts)
  runner("gdal_translate -of png -outsize 1000 1000 #{final_file}.tif #{final_file}.small.png", opts)
end
