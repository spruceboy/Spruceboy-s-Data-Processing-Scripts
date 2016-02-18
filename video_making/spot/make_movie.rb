#!/usr/bin/env ruby
#
require "pp"
require "yaml"


items = ARGV.sort

count = 0
0.upto(items.length-2) do |index| 
 	puts("Working on #{index} of #{items.length-2}")
        start_thumb = items[index]
        end_thumb =  items[index+1]
	location = "locations/" + File.basename(start_thumb, ".jpg") + ".png"
        system("montage #{start_thumb} #{end_thumb} -mode Concatenate  -tile 1x2 tmp.png")
	0.upto(1024/10) do |y_inc|
		frame = sprintf("frames/frame_%010d.jpg", count)
		frame_l = sprintf("frames_l/frame_%010d.jpg", count)
		#label = File.basename(start_thumb, ".jpg")
		label = File.basename(items[index], ".jpg")
		location = "locations/" + File.basename(start_thumb, ".jpg") + ".x.#{y_inc}.jpg"
		
		s = "convert #{start_thumb} tmp.png -geometry +0-#{y_inc*10} -composite  -pointsize 24 -fill white  -undercolor '#00000040' -gravity SouthWest -annotate +5+5 '#{label}' #{frame}"
		system(s)
		s = "convert #{frame} #{location} -geometry +#{1024-185}+#{1024-185} -composite logos/logo_trans.png -geometry +#{1024-(399+5)}+#{5} -composite #{frame_l}"
                system(s)
		#system("display #{frame_l}")
		#exit
		count += 1
	end
end


