require "rubygems"
require "yaml"
require "pp"


config = File.open("template.yml") {|fd| YAML.load(fd) }
pp config


y_min = config["bounds"]["y_min"]
y_max = config["bounds"]["y_max"]
x_min = config["bounds"]["x_min"]
x_max = config["bounds"]["x_max"]

pp y_min
pp y_max

y_steps = 1 + ((y_max - y_min) / ( config["res"]["y"] *config["result_size"]["y"])).to_i 
x_steps = 1 + ((x_max - x_min) / ( config["res"]["x"] *config["result_size"]["x"])).to_i 
y_delta = ( config["res"]["y"]*config["result_size"]["y"])
x_delta = ( config["res"]["x"] *config["result_size"]["x"])

pp y_steps
pp x_steps

gdalwarp = "gdalwarp -wo SKIP_NOSOURCE=YES -t_srs epsg:102006 -s_srs epsg:102006 -srcnodata \"0 0 0\" -dstnodata \"0 0 0 \" -te %f %f %f %f slurp/out*.tif foo.tif"

0.upto(y_steps) do |y|
	0.upto(x_steps) do |x|
		bbox_x = x_min + x*x_delta
		bbox_y = y_min + y*y_delta
		command = sprintf(gdalwarp, bbox_x,bbox_y, bbox_x + x_delta, bbox_y+y_delta, "murged_#{x}_#{y}.tif")
		puts command
		system(command)
		system("geotifcp", "-c", "lzw", "foo.tif", "murged_#{x}_#{y}.tif")
		system("rm -v -f foo.tif")
	end
end

