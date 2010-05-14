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

def write_wld(path,cfg)
  s = path.split(".")
  s.pop
  s = s.join(".")
  s += ".wld"
  
  #affine"=>[560290.5932, 0.6, 0.0, 7126029.9645, 0.0, -0.6]
  #Example
#25.40000078[1]
#0.00000000 [2]
#0.00000000 [4]
#-25.40000078 [5]
#493568.398193100002 [0]
#7440989.090747700073[3]
  File.open(s, "w") do |fd|
      fd.puts(cfg["affine"][1])
      fd.puts(cfg["affine"][2])
      fd.puts(cfg["affine"][4])
      fd.puts(cfg["affine"][5])
      fd.puts(cfg["affine"][0])
      fd.puts(cfg["affine"][3])
  end
  
end


##
# Options..
opts = GetoptLong.new(
    [ "--geo_source",         "-g",   GetoptLong::REQUIRED_ARGUMENT ],
    [ "--infile",             "-i",   GetoptLong::REQUIRED_ARGUMENT ],
    [ "--outfile",            "-o",   GetoptLong::REQUIRED_ARGUMENT ],
    [ "--gdal_args",          "-c",   GetoptLong::REQUIRED_ARGUMENT ],
    [ "--help",               "-h",   GetoptLong::NO_ARGUMENT ]
)

begin
  opts.each do |opt, arg|
    case opt
      when  "--geo_source"
        puts("Reading geo information from #{arg}")
        @geo_info = get_geo_info(arg)
      when "--infile"
        @infile = arg
      when "--outfile"
        @outfile = arg
      when "--gdal_args"
        @gdalargs = arg
    end
  end
rescue
    puts("Hmmm, errored out while arg processing.. not sure what the deal is..")
end
#pp @geo_info
write_wld(@infile, @geo_info)
runner("gdal_translate #{@gdalargs if (@gdalargs) } -a_srs \"#{@geo_info["s_srs"]}\" #{@infile} #{@outfile}")


