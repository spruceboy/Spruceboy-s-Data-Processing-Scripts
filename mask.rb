#!/usr/bin/env ruby
require "rubygems"
require "pp"
require "gdal_helper"


def should_mask(mask, x)
  return true if (mask[x] == 0)
  return false if (mask[x] == 1)
  puts "Strange mask value found at #{x} .."
end

#basic plan - open image,dim image by 25%, set the projection and geo_trans, then quit, job done.
# Open a tiff to write to, with default create options (TILED=YES, COMPRESS=LZW) to write to..
if (ARGV.length != 3)
  puts("Usage: ./mask.rb (infile) (mask) (outfile)")
  exit(-1)
end

infile = GdalFile.new(ARGV[0])
maskfile = GdalFile.new(ARGV[1])
outfile = GdalFile.new(ARGV[2], "w", infile.xsize,infile.ysize,infile.number_of_bands,"GTiff", infile.data_type, ["COMPRESS=DEFLATE", "TILED=YES", "BIGTIFF=YES"])

infile.each_line_with_index do |y_index,data|
  puts("\t#{y_index}") if (y_index%10 == 0 && ENV["DEBUG"])
  mask = maskfile.read_band(0, 0, y_index, infile.xsize,1)
  0.upto(infile.xsize-1) do |xsample|
    if (should_mask(mask, xsample))
      0.upto(infile.number_of_bands-1) {|band_index| data[band_index][xsample] = 0}
    else
      0.upto(infile.number_of_bands-1) { |band_index| data[band_index][xsample] = 1 if ( data[band_index][xsample] == 0 )}
    end
  end
  outfile.write_bands(0,y_index,infile.xsize,1,data)
end
# Set the projection
outfile.set_projection(infile.get_projection)
# set the geo transform (world file)
outfile.set_geo_transform(infile.get_geo_transform)



