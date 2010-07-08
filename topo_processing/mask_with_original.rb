#!/usr/bin/env ruby
require "rubygems"
require "pp"
require "gdal_helper"

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
  mask = maskfile.read_band(0, 0, y_index, infile.xsize,1)
  data.each do |band|
    band.each_index do |x_index|
      case (mask[x_index])
        when 1
          #its ok.. do nothing..
        when 0
          #whipe
          band[x_index] = 0
        else
          puts("Strange value at #{x_index}, #{y_index} => #{band[x_index]}")
        end
    end
  end
  outfile.write_bands(0,y_index,infile.xsize,1,data)
end
# Set the projection
outfile.set_projection(infile.get_projection)
# set the geo transform (world file)
outfile.set_geo_transform(infile.get_geo_transform)
