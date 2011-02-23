require "rubygems"
require "yaml"
require "pp"


ARGV.each do |x|
	system("gunzip -v #{x}")
	x = File.dirname(x) + "/" + File.basename(x, ".gz")
	system("gdal_translate -a_nodata \"0 0 0\" -co INTERLEAVE=BAND -co COMPRESS=lzw -co TILED=yes #{x} foo.tif")
	system("gdaladdo -r average foo.tif 2 4 8 16 32 64 128 256 512 ")
	system("gzip #{x}")
	system("mv foo.tif #{x}")
end

