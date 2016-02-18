require "yaml"
require "pp"
#makes a small location overview..
ext = ".tif"
fiddle_blue_marble = 500000
fiddle_drg = 20000

ARGV.each do |x|
	shape_fl = "shapes_aa/" + File.basename(x, ".tif") + ".shp"
	location = "locations/" + File.basename(x,".tif")
	raise ("Cannot find #{shape_fl} for #{x}!") if (!File.exists?(shape_fl))
	center = YAML.load(`gdal_list_corners #{x}`)["center"]
	pp center
	#system("cp location.tif #{location}")
	fiddle = fiddle_blue_marble
	system("gdal_translate -outsize 180 180 -projwin #{center["east"]-fiddle} #{center["north"]+fiddle}  #{center["east"]+fiddle} #{center["north"]-fiddle} /hub/bdl/production/500_meter/alaska_albers/blue_marble_alaska_albers.tif  #{location}.tif")
	fiddle = fiddle_drg
	system("gdal_translate -projwin #{center["east"]-fiddle} #{center["north"]+fiddle}  #{center["east"]+fiddle} #{center["north"]-fiddle} -outsize 1024 1024 /hub/bdl/production/drg/redone/250k.shaded.aa.tif #{location}.drg.tif")
	system("gdal_rasterize -burn \"255 0 0 \" -l #{File.basename(shape_fl, ".shp")} #{shape_fl} #{location}.tif")
	system("convert  #{location}.tif  #{location}.png")
	system("gdal_rasterize -burn \"255 0 0 \" -l #{File.basename(shape_fl, ".shp")} #{shape_fl} #{location}.bg.tif")
	system("gdalwarp -ts 1024 1024  #{location}.drg.tif #{x} #{location}.drg.data.tif")
end
