require "yaml"

compress="-flate"

ARGV.each do |x|
	xx = File.basename(x, ".gz")
	xxx = File.basename(xx, ".tif")
	system("zcat #{x} > #{xx}")
	cfg = YAML.load(`gdal_list_corners #{xx}| grep -v SGI`)
	wld_file = cfg["affine"][1].to_s + "\n" +
		"0 \n",
		"0 \n", 
		cfg["affine"][5].to_s  + "\n" +
		(cfg["geometry_en"]["upper_left_east"] + cfg["affine"][1]*0.5 ).to_s  + "\n" +  
		(cfg["geometry_en"]["upper_left_north"] + cfg["affine"][5]*0.5).to_s + "\n" 
		
	system("tifftopnm #{xx} | ppmbrighten -v +100 | pamtotiff #{compress} > #{xxx}.v.100.tif")
	system("tifftopnm #{xx} | ppmbrighten -v +100 | pamtotiff #{compress} > #{xxx}.s.100.tif")
	system("tifftopnm #{xx} | pamtotiff #{compress} > #{xxx}.stock.tif")
	system("rm", "-v", xx)

	["#{xxx}.v.100", "#{xxx}.s.100", "#{xxx}.stock"].each do |y|
	       File.open(y+".wld", "w"){|fd| fd.puts(wld_file) }
        end
end

system("gdalbuildvrt v.100.vrt *v.100.tif")
system("gdalbuildvrt s.100.vrt *s.100.tif")
system("gdalbuildvrt stock.vrt *stock.tif")
["v.100", "s.100", "stock"].each do |y|
	system("gdal_translate -co BIGTIFF=YES -a_srs epsg:4326 -co TILED=YES -co COMPRESS=LZW #{y}.vrt #{y}.tif")
	system("add_overviews.rb", "-m", y + ".tif")
	system("gdal_translate", "-of", "JPEG", "-outsize", "5%", "5%", y + ".tif", y + ".overview.jpg")
end
