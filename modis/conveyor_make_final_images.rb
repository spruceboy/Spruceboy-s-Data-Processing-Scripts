#!/bin/env  ruby
require "fileutils"


image_dir = ARGV[0]

#day time stuff 
if ( Dir.glob(image_dir + "/*.cal250.hdf").length != 0)
	#Make natural color images
	system("make_modis_natural_color.rb --modis-special-color #{image_dir}")
	system("make_modis_natural_color.rb  --red 2 --green 6 --blue 1_500m -p 1 --modis-special-color #{image_dir}")
	system("make_modis_natural_color.rb  --red 7 --green 2 --blue 1_500m -p 1 --modis-special-color #{image_dir}")
	system("make_modis_image.rb  --red 3 --green 6 --blue 7  -s '\\-percentile-range 0.02 0.98' #{image_dir}")
end
#Emisive thermal images
system("make_modis_night.rb #{image_dir}")

File.open("#{image_dir}/#{File.basename(image_dir)}.finished", "w"){|fd| fd.puts("Done.")}
