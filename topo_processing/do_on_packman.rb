#!/usr/bin/env ruby
require "fileutils"

ARGV.each do |x|
  x_dir = File.basename(x, "-srcdata.tar.gz")
  FileUtils.mkdir(x_dir)
  FileUtils.cd(x_dir)  do |it|
    system("tar", "-xvf", x)
  end
  system("ruby", File.dirname(__FILE__)+"/../processes_w_mask.rb", x_dir + "/gina-extras/tagger.yml")
end

basename = File.basename(File.dirname(ARGV.first)) + "."
system("gdalwarp", "-rb", "-srcnodata", "0 0 0","-dstnodata", "0 0 0","-co","COMPRESS=DEFLATE", "-co", "TILED=YES", "-co", "BIGTIFF=YES", *Dir.glob("*/*aa.filtered.tif"), basename + "combined.aa.tif")
system("gdalwarp","-rb",  "-srcnodata", "0 0 0","-dstnodata", "0 0 0","-co","COMPRESS=DEFLATE", "-co", "TILED=YES", "-co", "BIGTIFF=YES", *Dir.glob("*/*geo.filtered.tif"), basename+ "combined.geo.tif")
system("gdalwarp", "-rb", "-srcnodata", "0 0 0","-dstnodata", "0 0 0","-co","COMPRESS=DEFLATE", "-co", "TILED=YES", "-co", "BIGTIFF=YES", *Dir.glob("*/*google.filtered.tif"), basename + "combined.google.tif")
