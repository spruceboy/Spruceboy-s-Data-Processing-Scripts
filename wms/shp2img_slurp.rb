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

y_steps = 1 + ((y_max - y_min) / ( config["res"]["y"] *config["request_size"]["y"])).to_i 
x_steps = 1 + ((x_max - x_min) / ( config["res"]["x"] *config["request_size"]["x"])).to_i 
y_delta = ( config["res"]["y"]*config["request_size"]["y"])
x_delta = ( config["res"]["x"] *config["request_size"]["x"])

pp y_steps
pp x_steps


command_template = "shp2img -m /www/wms/apps/bdl/bdl_alaska.map -o %s -e %.20f %.20f %.20f %.20f -s %d %d -i image/tiff -l bdl_high_res_full"

0.upto(y_steps) do |y|
	0.upto(x_steps) do |x|
		bbox_x = x_min + x*x_delta
		bbox_y = y_min + y*y_delta
		#url = sprintf(config["url"], bbox_x,bbox_y, bbox_x + x_delta, bbox_y+y_delta, 
		#	config["request_size"]["x"], config["request_size"]["y"], config["proj"] )
		command = sprintf(command_template,  "/hub/bdl/production/update/out_#{x}_#{y}.tif",  bbox_x,bbox_y, bbox_x + x_delta, bbox_y+y_delta, 
			config["request_size"]["x"], config["request_size"]["y"])
		puts command
		system(command)
		#system("geotifcp", "-c", "lzw", "out_#{x}_#{y}.tif", "slurp/out_#{x}_#{y}.tif")
		#system("rm -v -f out_#{x}_#{y}.tif")
		system("gzip", "-v",  "out_#{x}_#{y}.tif")
		system("mv", "-v",  "out_#{x}_#{y}.tif.gz", "slurp/")
	end

	sleep(5)
end

