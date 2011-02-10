#/usr/bin/env ruby
#note - very short and dirty script to generate frames for a ndvi movie..

def ndvi_file_to_date (s) 
	#MT3RG_2007_50-56_250m_composite_ndvi.rgb.jpg
	 bits = s.split("_")
	 start_day = bits[2].split("-").first
	return(Time.gm(bits[1].to_i, 1,1,0,0,0) + start_day.to_i * 24*60*60)
end


#order the args..
ARGV.sort!

puts ARGV.join("\n")
count =  0
0.upto(ARGV.length-2) do |x|
	puts("Working on #{ARGV[x]}..")
	0.upto(10) do |pb|
		frame = sprintf("frames/frame_%05d.jpg", count)
		anotated_frame =  sprintf("frames/an_frame_%05d.jpg", count)
		src_perc = (10-pb)*10
		dst_perc = pb*10
	
		date = ndvi_file_to_date(ARGV[x]).strftime("%B %d, %Y")
		date = ndvi_file_to_date(ARGV[x+1]).strftime("%B %d, %Y") if (pb > 5)

		system("composite -dissolve #{src_perc}x#{dst_perc}  #{ARGV[x]} #{ARGV[x+1]} #{frame}") if (!File.exists?(frame))
		system("convert  #{frame}  -pointsize 24 -fill white  -undercolor '#00000040'  -gravity SouthWest -annotate +5+5 'MODIS NDVI: #{date}'  #{anotated_frame}")

		raise ("Problem! #{anotated_frame} does not exists") if (!File.exists?(anotated_frame))
		raise ("Problem! #{frame} does not exists") if (!File.exists?(frame))
		count += 1
	end
end
