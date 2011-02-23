
#makes a small location overview..

ARGV.each do |x|
	shape_fl = "shapes_aa/" + File.basename(x, ".jpg") + ".shp"
	location = "locations/" + File.basename(x,".jpg") + ".tif"
	raise ("Cannot find #{shape_fl} for #{x}!") if (!File.exists?(shape_fl))
	system("cp location.tif #{location}")
	system("gdal_rasterize -burn \"255 0 0 \" -l #{File.basename(shape_fl, ".shp")} #{shape_fl} #{location}")
end
