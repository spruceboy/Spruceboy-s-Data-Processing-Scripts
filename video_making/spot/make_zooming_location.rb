require "yaml"
require "pp"
#makes a small location overview..
ext = ".tif"
fiddle_blue_marble = 600000
fiddle_inc = 0.98

ARGV.each do |x|
	shape_fl = "shapes_aa/" + File.basename(x, ".jpg") + ".shp"
	location = "locations/" + File.basename(x,".jpg")
	raise ("Cannot find #{shape_fl} for #{x}!") if (!File.exists?(shape_fl))
	center = YAML.load(`gdal_list_corners #{x}`)["center"]
	pp center
	#system("cp location.tif #{location}")

	fiddle=fiddle_blue_marble	
	0.upto(1024/10) do |i|
		system("gdal_translate -q -outsize 180 180 -projwin #{center["east"]-fiddle} #{center["north"]+fiddle}  #{center["east"]+fiddle} #{center["north"]-fiddle} /hub/bdl/production/500_meter/blue_marble_alaska_albers.tif  #{location}.tif")
		fiddle *= fiddle_inc
		system("gdal_rasterize -q -burn \"255 0 0 \" -l #{File.basename(shape_fl, ".shp")} #{shape_fl} #{location}.tif")
        	system("convert -quiet  #{location}.tif  #{location}.x.#{i}.jpg")
		system("rm #{location}.tif")
	end
end
