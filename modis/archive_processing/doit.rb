#!/bin/env  ruby
# driver for conveyor
require "fileutils"

def system(x)
	puts("Running:#{x}")
	Kernel.system(x)
end

done_dir = "/home/processing/fast/modis/done/"
final_dir = "/hub/processing/modis_inprogress/"
bad_dir =  "/hub/temp/jcable/bad/"

ARGV.each do |i|
        hour_of_the_day = File.basename(i).split(".")[2][0,2].to_i
	puts hour_of_the_day
        next if ( hour_of_the_day > 23 || hour_of_the_day < 19 )

	done = done_dir + "/" + File.basename(i)
	final = final_dir +"/" +  File.basename(i)
	working = File.basename(i)
	next if (File.exists?(done) || File.exists?(working) || File.exists?(final))

	system("mkdir -v #{working}")
	system("mkdir -v #{done}")

	FileUtils.cd(working) do 
		#0 copy	
		system("scp -c arcfour webdev@maybe.x.gina.alaska.edu:#{i} .")
		#1 do_aqua/do_terra
		if ( File.basename(i)[0] == "a")
                	system("do_aqua.rb #{File.basename(i)}")
        	else
                	system("do_terra.rb #{File.basename(i)}")
        	end

		if (Dir.glob("*/*cal250.hdf").length > 0 )
			image_dir = Dir.glob("*/?1*cal250.hdf").first
			image_dir = File.dirname(image_dir)+"/" + File.basename(image_dir, ".cal250.hdf")
			system("generate_modis_bands.rb #{image_dir}")
			
			image_dir = File.dirname(image_dir)
			#3 make tifs
		        system("make_modis_natural_color.rb --modis-special-color #{image_dir}")
        		system("make_modis_natural_color.rb  --red 2 --green 6 --blue 1_500m -p 1 --modis-special-color #{image_dir}")
        		system("make_modis_natural_color.rb  --red 7 --green 2 --blue 1_500m -p 1 --modis-special-color #{image_dir}")
        		system("make_modis_image.rb  --red 3 --green 6 --blue 7  -s '\\-percentile-range 0.02 0.98' #{image_dir}")
			
			["ATM1_500_ATM4_ATM3_ATM1.alaska_albers.tif", "2_6_1_500m_1.alaska_albers.tif", "3_6_7.alaska_albers.tif", "7_2_1_500m_1.alaska_albers.tif"].each do |z|
				item = Dir.glob("*/*#{z}")
				if (item.length != 1)
					raise "can't find #{z}"
				end	
				item = item.first
				system("to_jpeg_tif.rb #{item} #{done}/#{File.basename(item, ".tif")}.jpg.tif")
			end
		end
	end
	system("mv -v #{done} #{final}")
	system("rm -rf #{working}")
end

