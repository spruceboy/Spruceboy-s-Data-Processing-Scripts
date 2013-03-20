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
  This util makes a natural color image with a custom enhancement. Wahoo.

Usage: 
	make_modis_natural_color.rb [options] <modis dir> 
where [options] is:
EOS

  opt :bg, "background_band", :default =>  "31"
  opt :red, "red band", :default =>  "ATM1_500"
  opt :green, "green band", :default =>  "ATM4"
  opt :blue, "blue band", :default =>  "ATM3"
  opt :pan, "pan band", :default => "ATM1"
  opt :verbrose, "Maxium Verbrosity.", :short => "V"
  opt :dry_run, "Don't actually run the command(s)"
  opt :area, "Area to be used", :default => "alaska_albers"
  opt :stretch, "Stretch to be used, be sure to quote!", :default => "-percentile-range 0.02 0.98"
  opt :rename, "Rename to this extention", :type=>String
  opt :modis_special_color, "Don't contrast stretch, use the modis rapid responce color scheme."
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
  tmp_name = "rgb_" + opts[:area]+ ".tmp"
  red = get_band(opts[:red], opts[:area])
  green = get_band(opts[:green], opts[:area])
  blue = get_band(opts[:blue], opts[:area])
  runner("gdalbuildvrt -resolution lowest -separate #{tmp_name}.vrt #{red} #{green} #{blue}", opts)

  if ( opts[:modis_special_color])
  	runner("modis_natural_color_stretch #{tmp_name}.vrt #{tmp_name}.tif", opts)
  else
	runner("gdal_contrast_stretch #{contrast_options} #{tmp_name}.vrt #{tmp_name}.tif", opts)
  end

  final_file =  File.basename(get_band(opts[:red], opts[:area])).split(".")[0,3].join(".")
  temp_file = ""
  if ( opts[:pan] != "none" )
    temp_file = tmp_name + "_" + opts[:pan]
    final_file += "_" + opts[:red] + "_" + opts[:green] + "_" + opts[:blue] + "_" + opts[:pan] 
    pan = get_band(opts[:pan], opts[:area])
    if ( opts[:modis_special_color])
       	runner("modis_natural_color_stretch #{pan} #{pan}.tmp", opts)
    else
    	runner("gdal_contrast_stretch #{contrast_options} #{pan} #{pan}.tmp", opts)
    end
    runner("gdal_landsat_pansharp -ndv 0 -rgb #{tmp_name}.tif -pan #{pan}.tmp -o #{temp_file}.tif", opts)
    runner("rm -v #{pan}.tmp", opts)
  else
    temp_file = tmp_name 
    final_file += "_" + opts[:red] + "_" + opts[:green] + "_" + opts[:blue] 
  end

  temp_file = temp_file + ".tif"

  if (opts[:rename])
        final_file = File.basename(get_band(opts[:red], opts[:area])).split(".")[0,3].join(".") + "." + opts[:rename]
  end

  final_file += "." + opts[:area]
  runner("gdal_translate #{gdal_opts} #{temp_file} #{final_file}.tif ", opts)
  runner("add_overviews.rb #{final_file}.tif ", opts)
  runner("rm -v #{temp_file} #{tmp_name}.vrt #{tmp_name}.tif", opts)
  runner("gdal_translate -of png -outsize 1000 1000 #{final_file}.tif #{final_file}.small.png", opts)

  ##
  # see if a background is needed.
  if (opts[:bg])
        bg = get_band(opts[:bg], opts[:area])
        runner("gdal_contrast_stretch #{contrast_options} #{bg} #{bg}.tmp", opts)
        runner("gdal_translate #{gdal_opts} -b 1 -b 1 -b 1 #{bg}.tmp #{bg}.tmp.tif", opts)
        runner("gdalbuildvrt -resolution highest #{temp_file}.vrt #{bg}.tmp.tif #{final_file}.tif", opts)
	runner("gdal_translate #{gdal_opts} #{temp_file}.vrt #{final_file}.bg.#{opts[:bg]}.tif ", opts)
  	runner("add_overviews.rb  #{final_file}.bg.#{opts[:bg]}.tif", opts)
        system("rm", "-v", temp_file, bg+".tmp",  bg+".tmp.tif")
        temp_file = temp_file + ".vrt"
  end

end
