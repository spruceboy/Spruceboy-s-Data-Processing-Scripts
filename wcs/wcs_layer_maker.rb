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

ARGV.each do |i|
  info = get_geo_info(i)
  name_bits = i.split("/").last.split(".")
  name_bits.delete_at(-1)  #remote .tif or whatever
  name = name_bits.join(".")
  name = i.split("/").last.split(".")[-3] if (name == "aa" || name == "geo")

  name = name.split(/[^a-zA-Z01-9]/).join("_")

  puts("\tLAYER")
  puts("\t\tNAME \"#{name}\"")
  puts("\t\tSTATUS OFF")
  puts("\t\tTYPE RASTER")
      puts("\t\tDUMP TRUE")
      puts("\t\tDATA \"#{i}\"")
      puts("\t\tPROJECTION")
      puts("\t\t\t#{info["s_srs"].split(" ").join("\n\t\t\t")}")
      puts("\n")	
      puts("\t\tEND")
      puts("\t\tMETADATA")
      puts("\t\t  wms_label \"#{name}\"")
      puts("\t\t  wcs_label \"#{name}\"")
      puts("\t\t  ows_extent \"#{info["geometry_en"]["upper_left_east"]} #{info["geometry_en"]["lower_left_north"]} #{info["geometry_en"]["lower_right_east"]} #{info["geometry_en"]["upper_right_north"]}\"")
      puts("\t\t  wcs_resolution \"#{info["res_meters"]}\"")
      puts("\t\t  ows_srs \"EPSG:3338\"")
      #puts("\t\t  wcs_formats \"GEOTIFFFLOAT32\"")
      puts("\t\t  wcs_nativeformat \"geotiff\"")
      puts("\t\t  wcs_formats \"GEOTIFFBYTE\"")

      puts("\t\tEND")
  puts("\tEND")
end

