require "rubygems"
require "yaml"
require "pp"



config = File.open("template.yml") {|fd| YAML.load(fd) }

ARGV.each do |x|
	system("gunzip -v #{x}")
	item = File.basename(x, ".tif")

	config["projections"].each do |prj|	
		system("gdalwarp -rb -srcnodata \"0 0 0\" -dstnodata \"0 0 0\" "  +
				"-co COMPRESS=DEFLATE -co ZLEVEL=9 " +
				"-co TILED=yes " + 
				"-co BIGTIFF=YES " + 
				"-t_srs epsg:#{prj} #{item}.tif #{prj}_#{item}.tif" )
		system("gdaladdo -r average #{prj}_#{item}.tif 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192")
	end
	#system("gzip #{item}.tif.gz")
end

