
#short and dirty script snipit to convert ndvi datasets to frames for movie making..
ARGV.each {|x| system("convert #{x}\[2\] -resize 1280x1024\! #{File.basename(x, ".tif")}.png")}
