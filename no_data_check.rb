#!/usr/bin/env ruby
require "rubygems"
require "pp"
require "gdal_helper"


#basic plan - set everything that is 0,0,0 to red.
if (ARGV.length != 2)
  puts("Usage: no_data_check.rb (infile) (outfile)")
  exit(-1)
end

infile = GdalFile.new(ARGV[0])
outfile = GdalFile.new(ARGV[1], "w", infile.xsize,infile.ysize,infile.number_of_bands,"PNM", infile.data_type, [])

infile.each_line_with_index do |y_index,data|
  0.upto(infile.xsize-1) do |xsample|
    if ( data[0][xsample] == 0 && data[1][xsample] == 0  && data[2][xsample] == 0 )
      data[0][xsample] = 255
      data[1][xsample] = 0 
      data[2][xsample] = 0
    end
  end
  outfile.write_bands(0,y_index,infile.xsize,1,data)
end



