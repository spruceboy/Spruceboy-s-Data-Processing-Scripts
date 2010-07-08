#!/usr/bin/env ruby
require "rubygems"
require "gdal_helper"
require "pp"
require "yaml"

require 'getoptlong'



def usage ()
	puts("#{File.basename(__FILE__)}  [dem] [image] [shaded output]")
	exit()
end

def runner ( s )
  puts("Runner running \"#{s}\"")
  start_time = Time.now.to_f
  system(s)
  end_time = Time.now.to_f

  run_time = (end_time-start_time)
  if ( run_time > 60)
    printf("This run took %d m\n", (end_time-start_time)/60)
  else
    printf("This run took %d s\n", (end_time-start_time))
  end
end




image_file = ARGV[1]
dem_file = ARGV[0]
out_file = ARGV[2]

gdal_file = GdalFile.new(ARGV[1])
extents = gdal_file.get_extents
res = gdal_file.get_geo_transform[1]
proj = "epsg:900913"
runner("rm -v #{out_file} #{out_file}.temp.dem.tif")
runner("gdalwarp -co BIGTIFF=YES -t_srs #{proj} -rcs -co COMPRESS=deflate -tr #{res} #{res} -te #{extents["xmin"]} #{extents["ymin"]} #{extents["xmax"]} #{extents["ymax"]} #{dem_file} #{out_file}.temp.dem.tif")
runner("gdal_dem2rgb -valid-range '1..9000' -exag 1 -texture #{image_file} #{out_file}.temp.dem.tif #{out_file}.temp.shaded.tif")
runner(File.dirname(__FILE__)+ "/../mask.rb  #{out_file}.temp.shaded.tif #{image_file} #{out_file} ")
#runner("rm -vf #{out_file}.temp.shaded.tif #{out_file}.temp.dem.tif ")