#quick and dirty snipit to extract frames from ndvi datasets around the anchorage area
ARGV.each {|x| system("gdal_translate -of JPEG -srcwin 2714 4600 1280 1024 #{x} extracts/#{File.basename(x, ".tif")}.jpg")}
