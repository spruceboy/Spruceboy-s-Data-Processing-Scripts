#!/usr/bin/env ruby
require "rubygems"
require "getoptlong"


#basic template for warping..
# CACHEMAX controls amount of ram for io caching
# -wm controls amount of ram for warping..
command_template = "gdalwarp  -t_srs EPSG:900913 --config GDAL_CACHEMAX 1000 -wm 750 -dstnodata \"0 0 0\" -srcnodata \"0 0 0\" -co COMPRESS=LZW -co BIGTIFF=YES -co TILED=YES %s %s"

tasks = []

#opt = Getopt::Long.getopts( 
#			["--postfix", Getopt::OPTIONAL], 
#			["--threads", Getopt::OPTIONAL]
#		)


opts = GetoptLong.new(
  [ '--threads', '-t', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--postfix', '-p', GetoptLong::OPTIONAL_ARGUMENT ]
)


#parse options..
#Default to 3 threads, and postfix of .tif
no_threads = 3
postfix = ".tif"
opts.each do |opt, arg|
   case opt
     when '--threads' then no_threads = arg.to_i
     when '--postfix' then postfix=arg
   end
end

#loop through argv preparing commands for each..
ARGV.each do |x|
	target = File.basename(x, postfix) + ".google.tif"
        command = [sprintf(command_template,x, target)]
        command <<= "add_overviews.rb #{target}"
        to_do = command
        tasks.push(to_do)
end


threads = []
1.upto(no_threads) do
        threads << Thread.new do
                loop do
                        todo = tasks.pop
                        break if (todo == nil)
                        todo.each do |i|
                                if (i.class == Array)
                                        puts("Running (A): #{i.join(" ")}")
                                        system(*i)
                                else
                                        puts("Running: #{i}")
                                        system(i)
                                end
                        end
                end
        end
end

threads.each {|t| t.join}

