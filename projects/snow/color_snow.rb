#!/usr/bin/env ruby
require "rubygems"
require "gdal_helper"
require "pp"

##
# This is a very basic example using the helper library to do some real work - in this case taking a MODIS ndvi product
# that is scaled from 10,000 to -1000 and creating a nice color presentation of it.
# This is just an example, so YMMV.  Have fun - jc@alaska.edu

##

##
# Maps a value to a color set
def colorize(value, colormap)
	return colormap[value] if ( colormap[value]) 
	return [0,0,0]
end
        
##
# A color map for ndvi, adapted from GRASS. the format is [min value, max value, [starting r,g,b], [ending r,g,b]]
# this could of course be improved..
ndvi_colormap = { 24 => [76,230,0], 
	37 => [0,197,255], 
	39 => [0,77,168],
	50 => [204,204,204],
	100 => [127,255, 212],
	200 => [255,255,255]}

if (ARGV.length != 2)
  puts("Usage: ./ndvi_color.rb (infile) (outfile)")
  return -1
end

#input file
infile = GdalFile.new(ARGV[0])
#output file
outfile = GdalFile.new(ARGV[1], "w", infile.xsize,infile.ysize,3,"GTiff", String, ["TILED=YES"])
#set the projection related details on the output file
outfile.set_projection(infile.get_projection)
outfile.set_geo_transform(infile.get_geo_transform)

# Loop though each line, colorizing the data
infile.each_line_with_index do |y_index, data|
	out_data = [[],[],[]] #rbg array..
	
	# print some status details..
	if (y_index%100 == 0)
		STDOUT.write(".")
		STDOUT.flush
	end
	
	# loop though each sample, colorzing them.
	data[0].each_index do |x_index|
		# take each value, map it to a rgb, then put this in the bands to be output
		rgb  = colorize(data[0][x_index].to_i, ndvi_colormap)
		out_data[0][x_index] = rgb[0]
		out_data[1][x_index] = rgb[1]
		out_data[2][x_index] = rgb[2]
	end
	outfile.write_bands(0,y_index, infile.xsize, 1, out_data)
end

STDOUT.write("Done!\n")
