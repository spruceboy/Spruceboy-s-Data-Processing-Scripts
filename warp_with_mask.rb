#!/usr/bin/env ruby

require 'yaml'
require 'pp'

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
This utility takes a file with nodata set to "0,0,..", reprojects it and masks it properly so there are no nodata problems.  

It assumes the nodata values are 0 for each band.

Usage:
      warper.rb [options] <infile> <outfile>
where [options] is:
EOS

  opt :internal_mask, "Use interal nodata masks"
  opt :verbrose, "Maxium Verbrosity.", :short => "V"
  opt :skip_cache_check, "Skip check of GDAL_CACHEMAX"
  opt :small_tiff, "Don't use bigtiff option. Meaningfull only in the case of jpeg compressed tifs."
  opt :t_srs, "target projection (for example, \"epsg:3338\")", :type => String
  opt :s_srs, "source projection (for example, \"epsg:3338\")", :type => String
  opt :jpeg, "make a jpeg compressed tiff"
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
["add_mask", "add_overviews.rb", "masker"].each do |t|
  if (!File.exists?(File.dirname(__FILE__) +"/" + t))
      errors=true
      puts("Error: Could not find #{t}, which should be here: #{File.dirname(__FILE__)}")
  end
end
exit(-1) if (errors)
  

infile = ARGV[0]
outfile = ARGV[1]
tmpfile = ARGV[1] +".tmp"

puts("Info: using \"#{infile}\" as source ") if (opts[:verbrose])
puts("Info: using \"#{outfile}\" as output ") if (opts[:verbrose])


#get info of source file..
input_cfs = YAML.load(`gdal_list_corners #{infile}`)

#check the bands, make sure its reasonable..
if ( input_cfs["num_bands"] !=3 )
  puts("Error: #{infile} has #{input_cfs["num_bands"]}, in order for this to work it needs to have 3.")
  exit(-1)
end

#make temp image, compressed + tiled
puts("Info: generating temp image..")
runner(["gdal_translate", "-co", "TILED=YES", "-co","BIGTIFF=YES","-co", "COMPRESS=LZW",  infile, tmpfile ], opts)

#add mask
puts("Info: Adding mask to temp image..")
runner([File.dirname(__FILE__)+"/add_mask", tmpfile], opts)

#add overviews..
puts("Info: Adding overviews to temp image..")
runner([File.dirname(__FILE__)+"/add_overviews.rb", "-m",  tmpfile], opts)

puts("Info: Generating #{outfile}..")
additional_options=[]
additional_options += ["--config", "GDAL_TIFF_INTERNAL_MASK", "TRUE"] if (opts[:internal_mask])
additional_options += ["-co", "BIGTIFF=YES"] if (!opts[:small_tiff])
proj = ["-t_srs", opts[:t_srs]]
proj += ["-s_srs", opts[:s_srs]] if (opts[:s_srs])
runner(["gdalwarp","-dstnodata", "0 0 0", "-rcs", "-co", "TILED=YES", "-co", "COMPRESS=LZW"] + proj + additional_options + [tmpfile, tmpfile +".warp"], opts)
runner(["gdal_translate", "-co", "TILED=YES", "-co", "COMPRESS=LZW", "-b", "mask", tmpfile, tmpfile + ".mask"], opts)
runner(["gdalwarp","-co", "TILED=YES", "-co", "COMPRESS=LZW", "-t_srs", opts[:t_srs], tmpfile+".mask", tmpfile + ".mask.warp"], opts)
if (!opts[:jpeg])
  runner([File.dirname(__FILE__)+"/masker",tmpfile +".warp",  tmpfile + ".mask.warp", outfile], opts)
  runner([File.dirname(__FILE__)+"/add_mask",outfile], opts)
  runner([File.dirname(__FILE__)+"/add_overviews.rb", "-m", outfile], opts)
else
  runner([File.dirname(__FILE__)+"/masker",tmpfile +".warp",  tmpfile + ".mask.warp", tmpfile + ".prejpeg"], opts)
  runner([File.dirname(__FILE__)+"/add_mask",tmpfile + ".prejpeg"], opts)
  runner([File.dirname(__FILE__)+"/add_overviews.rb", "-m", tmpfile + ".prejpeg"], opts)
  runner(["gdal_translate","-co", "TILED=YES", "-co", "COMPRESS=JPEG","-co","COPY_SRC_OVERVIEWS=YES","-co","PHOTOMETRIC=YCBCR", "-co", "JPEG_QUALITY=90"] + additional_options + [tmpfile, outfile], opts)
end



if (!opts[:internal_mask])
  puts("Info: Adding overviews to mask..")
  runner([File.dirname(__FILE__)+"/add_overviews.rb", "-m", outfile +".msk"], opts)
end


puts("Info: Deleting #{tmpfile} && #{tmpfile}.msk") if (opts[:verbrose])
runner(["rm", tmpfile], opts)
[".mask.warp",".msk", ".mask", ".warp", ".prejpeg"].each {|d| runner(["rm", tmpfile+d], opts) if (File.exists?(tmpfile+d))} 

puts("Info: Done.")




