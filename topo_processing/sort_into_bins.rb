#!/usr/bin/env ruby
require "rubygems"
require "gdal_helper"
require "pp"
require "yaml"

require 'getoptlong'


# == Synopsis
#
# hello: greets user, demonstrates command line parsing
#
# == Usage
#
# hello [OPTION] ... DIR
#
# -h, --help:
#    show help
#
# --bin_size x, -b x:
#    size of bins to sort to (integer, for example 10000)
#
# --outdir [name], -o:
#    name of directory to sort to
#
# DIR: The directory in which to issue the greeting.

def usage ()
	puts("#{File.basename(__FILE__)}  [--help] [--bin_size|-b] [--outdir|-o]")
	exit()
end


def get_index (bounds, extents, size)
	xinc= (extents["xmin"] - bounds["xmin"]).to_i / size
	yinc= (extents["ymin"] - bounds["ymin"]).to_i / size
	"#{xinc}_#{yinc}"
end

opts = GetoptLong.new(
      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
      [ '--bin_size', '-b', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--outdir', '-o', GetoptLong::REQUIRED_ARGUMENT ]
    )


out_dir = nil
bin_size = nil

opts.each do |opt, arg|
	case opt
		when '--help'
		  usage()
		when '--bin_size'
			bin_size=arg.to_i
		when '--outdir'
			out_dir = arg
	end
end

if (!out_dir || !bin_size)
	usage
end

bounds = nil

ARGV.each do |item|
	gdal_file = GdalFile.new(item)
	extents = gdal_file.get_extents
	bounds = extents if (bounds == nil)
	bounds["xmin"] = extents["xmin"] if (  	bounds["xmin"] > extents["xmin"] )
	bounds["ymin"] = extents["ymin"] if (  	bounds["ymin"] > extents["ymin"] )
	bounds["xmax"] = extents["xmax"] if (  	bounds["xmax"] < extents["xmax"] )
	bounds["ymax"] = extents["ymax"] if (  	bounds["ymax"] < extents["ymax"] )
end

sorted = {}

ARGV.each do |item|
	gdal_file = GdalFile.new(item)
	extents = gdal_file.get_extents
	key = get_index(bounds, extents, bin_size)
	
	sorted[key] = [] if (!sorted[key])
	sorted[key] << item
end

pp sorted

puts("going to sort <ctr> c to exit..")
10.downto(1) do |x|
	puts(".. #{x}")
	sleep(1)
end
puts("go!")

system("mkdir #{out_dir}") if (!File.exists?(out_dir))
counter = 0
sorted.keys.each do |i|
	target = out_dir + "/" + i
	system("mkdir #{target}") if (!File.exists?(target))
	sorted[i].each do |zebra|
		basename = File.basename(zebra)
		system("cp -v #{zebra} #{target}/#{counter}_#{basename}")
		counter += 1
	end
end

