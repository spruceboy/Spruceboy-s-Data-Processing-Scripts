#!/usr/bin/env ruby
require 'rubygems'
require 'open3'
#require 'RMagick'
require 'yaml'
require 'pp'

projections = [
	{ "projection" => "epsg:3338", "projection_tag" => "aa"},
	{ "projection" => "epsg:900913", "projection_tag" => "google" },
	{ "projection" =>"epsg:4326",  "projection_tag" => "geo"}]

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

def do_repo (x,output_path, epsg,source_proj, ext,note, resampling="-rcs")

        base = File.basename(x, ext)

        s  = "gdalwarp --config GDAL_CACHEMAX 512 -wm 256 -s_srs '#{source_proj}' -co BIGTIFF=YES -co TILED=YES -co COMPRESS=DEFLATE #{resampling} -t_srs '#{epsg}' #{x} #{output_path}"
        runner(s)
        return output_path
end

ARGV.each {|z|
	cfg = YAML.load(File.open(z))
	scene_id = cfg["data"]["scene_id"]
	ingest_dir = scene_id+ "_processed"
	finaldir = ingest_dir
	
	bands_in = ""
        bands_in =  " -b " + cfg["data"]["bands"].split(" ").join(" -b ") if ( cfg["data"]["bands"] )

	resampling ="-rb"

	if (!File.exists?(ingest_dir))
		Dir.mkdir( ingest_dir )
	else
		puts("#{finaldir} allready exists... perhaps you should deal with this first.")
		exit(-1)
	end

	x = File.dirname(z) + "/../" + cfg["data"]["image_file"]
	mask =  Dir.glob(File.dirname(z) + "/*pbm").first

	ext = "." + x.split(".").last
	
	# Step 1 - make a temp directory to do work in..
	workdir=  scene_id+".working"
	while ( File.exists?(workdir) )
		workdir = workdir + "x"
	end
	Dir.mkdir(workdir)
	
	data_file = workdir + "/data_file.tif"
	mask_file = workdir + "/mask.tif"
	filtered_base = workdir + "/data_file.filtered"
	# Step 2.1 - reformat data file..
	runner("gdal_translate #{bands_in} -co TILED=YES -co BIGTIFF=YES -co COMPRESS=DEFLATE #{x} #{data_file}")
	
	# Step 2.2 - reformat mask file
	runner("pnmtotiff #{mask} > #{mask_file}.tmp")
	runner("#{File.dirname(__FILE__)}/mask_to_geotif.rb  #{mask_file}.tmp #{data_file} #{mask_file}")
	
    	projections.each  do |proj| 
        	projection_tag = proj["projection_tag"]
		projection = proj["projection"]
        	source_projection = cfg["data"]["s_srs"]
        	
        	clean_data_file = finaldir +"/"+scene_id+"."+ proj["projection_tag"] + ".tif"
        	clean_data_file_filtered = finaldir +"/"+scene_id+"."+ proj["projection_tag"] + ".filtered.tif"

	    	##
		# Step 3.1 - repo data file..
		projected_data_file = do_repo(data_file, data_file + "." + projection_tag + ".tif", projection, source_projection, ".tif", projection_tag)
		
		##
		# Step 3.2 - repo mask file..
		projected_mask_file = do_repo(mask_file, mask_file + "." + projection_tag +".tif", projection, source_projection, ".tif", projection_tag, "")

		##
		# Step 4 - Cleanup data file....
		runner("#{File.dirname(__FILE__)}/mask.rb #{projected_data_file} #{projected_mask_file} #{clean_data_file}")
		
		# Step 4.1 - add overviews to data file..
		runner("~/bin/add_overviews.rb #{clean_data_file}")
		
		##
		# Step 5 - filter image
		runner("gdal_translate -of PNM #{clean_data_file} #{filtered_base}.pnm")
		runner("pnmnlfilt 0.0 1 #{filtered_base}.pnm | pnmnlfilt  -0.7 0.8 > #{filtered_base}.filtered.pnm")
		runner("#{File.dirname(__FILE__)}/copy_geo_info.rb --gdal_args \"-a_nodata '0 0 0' -co COMPRESS=DEFLATE -co TILED=YES -co ZLEVEL=9 -co BIGTIFF=YES\" --geo_source #{clean_data_file} --infile  #{filtered_base}.filtered.pnm --outfile #{filtered_base}.filtered.tif")
		runner("#{File.dirname(__FILE__)}/masker #{filtered_base}.filtered.tif #{projected_mask_file} #{clean_data_file_filtered}")
		runner("#{File.dirname(__FILE__)}/add_overviews.rb #{clean_data_file_filtered}")
    	end
    	
    	##
	# Cleanup..
	system("rm -rfv #{workdir}")
 }


