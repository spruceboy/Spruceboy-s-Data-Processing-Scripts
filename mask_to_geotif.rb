#!/usr/bin/env ruby
require "rubygems"
require "pp"
require "gdal_helper"

#basic plan - open image,dim image by 25%, set the projection and geo_trans, then quit, job done.
# Open a tiff to write to, with default create options (TILED=YES, COMPRESS=LZW) to write to..
if (ARGV.length != 3)
  puts("Usage: ./mask_to_geotif.rb mask_file source_file mask_as_tiff.tif")
  exit(-1)
end

maskfile = GdalFile.new(ARGV[0])
geo_tiff_file = GdalFile.new(ARGV[1])
outfile = GdalFile.new(ARGV[2], "w", maskfile.xsize,maskfile.ysize,maskfile.number_of_bands,"GTiff", maskfile.data_type, ["COMPRESS=DEFLATE", "TILED=YES", "BIGTIFF=YES"])

maskfile.each_line_with_index do |y_index,data|
  outfile.write_bands(0,y_index,maskfile.xsize,1,data)
end
# Set the projection
outfile.set_projection(geo_tiff_file.get_projection)
# set the geo transform (world file)
outfile.set_geo_transform(geo_tiff_file.get_geo_transform)



