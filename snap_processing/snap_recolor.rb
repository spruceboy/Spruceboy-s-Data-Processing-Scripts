#!/usr/bin/env ruby
require "rubygems"
require "gdal_helper"
require "pp"
require "yaml"

##
# This is a very basic example using the helper library to do some real work - in this case taking a MODIS ndvi product
# that is scaled from 10,000 to -1000 and creating a nice color presentation of it.
# This is just an example, so YMMV.  Have fun - jc@alaska.edu

##
# Finds the correct item in a colormap for a particular value
def find_color_range ( value, colormap )
        ##
        # Keep last, incase it is needed again - speed up 
        if (@last && @last[0] <= value && value <= @last[1])
                return @last
        end
        
        colormap.each do |color_set|
                if ( color_set[0] <= value && value <= color_set[1] )
                        @last = color_set
                        return color_set
                end
        end
	
	# outside the range of the color map, this is an error..
	raise(ArgumentError, "value requested is not in colormap.. value was #{value}", caller)
end


##
# Maps v to a range, given a min and max source and desitancation values.. wow, I can't spell..
def map_color(color_set, value)
	#give the color table some more reasonable names..
	# [min, max, [min r,g,b], [max r,g,b]]
	min = color_set[0]
	max = color_set[1]
	min_c = color_set[2]
	max_c = color_set[3]
	rgb=[] #requested color
	perc = (value.to_f - min.to_f)/(max - min) #percent between
	0.upto(2) { |zang| rgb[zang] = ((max_c[zang] - min_c[zang]) * perc + min_c[zang] ).to_i }
	rgb
end

##
# Maps a value to a color set
def colorize(value, colormap)
        @cache={} if (!@cache)
        return @cache[value] if (@cache[value])
        color_set = find_color_range(value, colormap)

        rgb = map_color(color_set, value)
        @cache[value]=rgb if (@cache.length < 10000) #cache first x items - deleting from the hash is slow
	rgb
end
        
##
# A color map for ndvi, adapted from GRASS. the format is [min value, max value, [starting r,g,b], [ending r,g,b]]
# this could of course be improved..
if (ARGV.length != 3)
  puts("Usage: ./recolor_color.rb (color file.yml) (infile) (outfile)")
  return -1
end

color_map = File.open(ARGV[0]){|fd| YAML.load(fd)}

#input file
infile = GdalFile.new(ARGV[1])
#output file
outfile = GdalFile.new(ARGV[2], "w", infile.xsize,infile.ysize,3,"GTiff", String, ["COMPRESS=DEFLATE", "TILED=YES"])
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
	0.upto(infile.xsize-1) do |x_index|
		#puts("(#{x_index}->#{data[0][x_index]})")
		if ( data[0][x_index] == -9999 ) # check to see if value is nodata..
			out_data[0][x_index] = out_data[1][x_index] = out_data[2][x_index] = 0.0
			next
		end
		
		# take each value, map it to a rgb, then put this in the bands to be outputA
		rgb  = colorize(data[0][x_index].to_f, color_map)
		out_data[0][x_index] = rgb[0]
		out_data[1][x_index] = rgb[1]
		out_data[2][x_index] = rgb[2]
	end
	outfile.write_bands(0,y_index, infile.xsize, 1, out_data)
end

STDOUT.write("Done!\n")
