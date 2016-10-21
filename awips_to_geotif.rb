#!/usr/bin/env ruby
# a very simple util to convert awips netcdf files to tifs for use outside awips

require 'yaml'
require 'pp'

WLD_FILES = { 
	"203" => [-4952960.856044003739953,  1000.000000000000000, 0.000000000000000, 381022.610378222307190, 0.000000000000000, -1000.000000000000000]
   }
EXTENT = { 
	"203_filliped" => [-4952960.856044003739953, 381022.610378222307190,3431039.143955996260047,-6857977.389621777459979] ,
	"203" => [-4952960.856044003739953, -6857977.389621777459979,3431039.143955996260047,381022.610378222307190]
  }

PROJS = {
	"203" => '+proj=stere +lat_0=90 +lat_ts=60 +lon_0=-150 +k=1 +x_0=0 +y_0=0 +a=6371200 +b=6371200 +units=m +no_defs '
  }

def runner ( command, opts)
  puts("Running: #{command.join(" ")}") if (opts[:verbrose])
  start_time = Time.now
  system(*command)
  puts("Done in #{(Time.now - start_time)/60.0}m.") if (opts[:verbrose])
end


## Command line parsing action..
require 'trollop'
parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
This util takes a standard grid 203 netcdf file for awips into a geotif.

Usage:
      awips_to_geotif.rb [options] <infile> <outfile>
where [options] is:
EOS

  opt :temp, "temp area", :type => String, :default => "./"
  opt :verbrose, "Maxium Verbrosity.", :short => "V"
  opt :skip_cache_check, "Skip check of GDAL_CACHEMAX"
  opt :grid, "the grid", :type => String, :default => "203"
end

opts = Trollop::with_standard_exception_handling(parser) do
  o = parser.parse ARGV
  raise Trollop::HelpNeeded if ARGV.length != 2 # show help screen
  o
end


if (!opts[:skip_cache_check] )
  if (!ENV["GDAL_CACHEMAX"])
      puts("Error: Please set GDAL_CACHEMAX to something useful by doing something like this \"export GDAL_CACHEMAX=2048\" and try again. ")
      puts("(This check can be skipped by using the \"--skip_cache_check\" flag)")
      exit(-1)
  else
    puts("Warning: GDAL_CACHEMAX is set to somthing pretty small #{ENV["GDAL_CACHEMAX"].to_i} (thats in mbytes)") if (ENV["GDAL_CACHEMAX"].to_i < 512)
  end
end


# first, verify that the required subprograms exist..
errors=false;
["add_overviews.rb"].each do |t|
  if (!File.exists?(File.dirname(__FILE__) +"/" + t))
      errors=true
      puts("Error: Could not find #{t}, which should be here: #{File.dirname(__FILE__)}")
  end
end
exit(-1) if (errors)
  

infile = ARGV[0]
outfile = ARGV[1]

puts("Info: using \"#{infile}\" as source ") if (opts[:verbrose])
puts("Info: using \"#{outfile}\" as output ") if (opts[:verbrose])


##
# Deal with gziped files
if (infile.split(".").last == "gz") 
	raise ("ungzip the files first please")
end

#File.open(outfile+".tfw", "w") {|fd| fd.puts(WLD_FILES[opts[:grid]].join("\n"))}
runner("gdal_translate -ot Byte -a_ullr #{EXTENT[opts[:grid]].join(" ")} -a_nodata 0 -a_srs \"#{PROJS[opts[:grid]]}\" -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 #{infile} #{outfile}", opts)
runner(File.dirname(__FILE__) +"/add_overviews.rb #{outfile}", opts)

