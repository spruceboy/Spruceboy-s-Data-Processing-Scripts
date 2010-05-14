#!/usr/bin/env ruby
require "rubygems"
require "yaml"
require 'getoptlong'
require "pp"


def runner ( s )
  puts("Runner running \"#{s}\"")
  start_time = Time.now.to_f
  system(s)
  end_time = Time.now.to_f

  run_time = (end_time-start_time)
  if ( run_time > 60)
    printf("This run took %d m\n", (end_time-start_time)/60)
  else
    printf("This run took %d s\n", (end_time-start_time))
  end
end


def get_geo_info (path)
  return YAML.load(`gdal_list_corners #{path}`)  
end

##
# Options..
opts = GetoptLong.new(
    [ "--gdal_args",          "-c",   GetoptLong::REQUIRED_ARGUMENT ],
    [ "--help",               "-h",   GetoptLong::NO_ARGUMENT ],
    [ "--resample",          "-r",   GetoptLong::REQUIRED_ARGUMENT ]
)

resample = "average"
gdalargs = "--config GDAL_CACHEMAX 500"
begin
  opts.each do |opt, arg|
    case opt
      when "--help"
        puts("./prog [--help|-h] [ --gdal_args| -c { '--config GDAL_CACHEMAX 1000'}][--resample|-r {average,gauss}]")
        exit
      when "--gdal_args"
        gdalargs = arg
      when "--resample"
        resample = arg
    end
  end
rescue
    puts("Hmmm, errored out while arg processing.. not sure what the deal is..")
end

ARGV.each do |item|
  geo_info = get_geo_info(item)
  list = ""
  i = 2
  max = geo_info["height"]
  max = geo_info["width"] if ( geo_info["width"] > max )

  while ( i*2 < max )
    list = list + " #{i} "
    i = i * 2
  end

  runner("gdaladdo -r #{resample} #{gdalargs if (gdalargs) } #{item} #{list}")
end


