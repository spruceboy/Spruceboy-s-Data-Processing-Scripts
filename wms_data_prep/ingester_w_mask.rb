#!/usr/bin/env ruby
require 'rubygems'
require 'open3'
#require 'RMagick'
require 'yaml'
require 'pp'

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


##
# reprojected and masks a data file
def do_repo (x,mask, epsg,source_proj, ext,note)
        base = File.basename(x, ext)

        output_path="#{@workdir}/#{base}_#{note}.premask.tif"
        final_output_path = "#{@workdir}/#{base}_#{note}.tif"
        projected_mask = "#{@workdir}/#{base}_#{note}_mask.tif"

	puts("do_repo: warping datafile..")
        s  = "gdalwarp -s_srs '#{source_proj}' #{@COMPRESS_OPS} -co TILED=YES -co BIGTIFF=YES #{@resampling} -srcnodata \"#{@no_data_in}\" -dstnodata \"#{@no_data_out}\" -t_srs '#{epsg}' #{x} #{output_path}"
        runner(s)
        puts("do_repo: warping mask..")
        s  = "gdalwarp #{@COMPRESS_OPS} -co TILED=YES -co BIGTIFF=YES -srcnodata 255 -dstnodata 0 -t_srs '#{epsg}' #{mask} #{projected_mask}"
        runner(s)
        puts("do_repo: Masking..")
        s = "#{File.dirname(__FILE__)}/../masker #{output_path} #{projected_mask} #{final_output_path}"
        runner(s)
        
        add_overviews(final_output_path)
        
	puts("do_repo: done (#{note})")
        return final_output_path
end


def add_overviews (i)
	puts("add_overviews: Adding overviews to #{i}")
	s = "#{File.dirname(__FILE__)}/../add_overviews.rb  #{i}"
	runner(s)
	puts("add_overviews: done")
end

def scale (x,epsg,source_proj,scale,out)
        output_path=out+".tif"
        
        puts("scale: making overview image..")
        s = "gdalwarp -co TILED=YES #{@COMPRESS_OPS} -tr #{scale} -srcnodata \"#{@no_data_in}\" -dstnodata \"#{@no_data_out}\" -t_srs #{epsg} #{x} #{output_path}"
        runner(s)
	add_overviews(output_path)
	puts("scale: done.")
	
        return output_path
end

##
# convert x to a tiled, lzw compressed bigtif..
def to_bigtiff(x, outfile)
	 extra = ""
	 extra = "-outsize 5% 5% " if (@debug)
         s = "gdal_translate #{extra} #{@COMPRESS_OPS} -co BIGTIFF=YES -co TILED=YES #{@bands_in}  #{x}  #{outfile}"
         runner(s)
         return outfile
end

class Gdal

	def Gdal.find_tag( ln, item)
	
		for x in ln 
			if ( x.scan(item).length>0)
			##puts ("found #{item} at #{x}")
			return x
			end
		end	

		raise RuntimeError ("Could not match #{item}")	
		
	end

        def Gdal.getextents ( path )
                #output = IO.popen(["gdalinfo",path],"r").readlines
                output = ""
		puts("running gdalinfo #{path}")
                Open3.popen3("gdalinfo",path) { |stdin, stdout, stderr|
                        output = stdout.readlines
                        }
                ln = output.length
	
		puts("Got #{ln} lines...")

                lr= Gdal.find_tag(output,"Lower Right").split(/\(|\)/)[1].split(",")
                ur = Gdal.find_tag(output,"Upper Right").split(/\(|\)/)[1].split(",")
                ll = Gdal.find_tag(output,"Lower Left").split(/\(|\)/)[1].split(",")
                ul = Gdal.find_tag(output,"Upper Left").split(/\(|\)/)[1].split(",")
                center = Gdal.find_tag(output,"Center").split(/\(|\)/)[1].split(",")
		xsize,ysize=output[0,4].join("").split("Size")[1].split(/\D+/)[1,2]


                #14: Origin = (559956.000000,7103851.800000)
                #13: Pixel Size = (0.60000000,-0.60000000)
                #12: Metadata:
                #11:  AREA_OR_POINT=Area
                #10:  Corner Coordinates:
                #9:  Upper Left  (  559956.000, 7103851.800) (145d46'18.07"W, 64d 3'22.23"N)
                #8:  Lower Left  (  559956.000, 7093131.600) (145d46'33.25"W, 63d57'35.98"N)
                #7:  Upper Right (  569950.200, 7103851.800) (145d34'1.23"W, 64d 3'15.49"N)
                #6:  Lower Right (  569950.200, 7093131.600) (145d34'18.94"W, 63d57'29.26"N)
                #5:  Center      (  564953.100, 7098491.700) (145d40'17.87"W, 64d 0'25.87"N)
                #4:  Band 1 Block=16657x1 Type=Byte, ColorInterp=Red
                #3:  Band 2 Block=16657x1 Type=Byte, ColorInterp=Green
                #2:  Band 3 Block=16657x1 Type=Byte, ColorInterp=Blue
                #1:  Band 4 Block=16657x1 Type=Byte, ColorInterp=Alpha

                xmin = ll[0];
                xmin = ul[0] if (ul[0] < xmin);

                xmax = lr[0];
                xmax = ur[0] if (ur[0] < xmin);

                ymin = ll[1];
                ymin = ul[1] if (ul[1] < xmin);

                ymax = lr[1];
                ymax = ur[1] if (ur[1] < xmin);


                return { "lr" => lr, "ur" => ur, "ll" => ll, "ul" => ul, "xmin" => xmin, "xmax" => xmax, "ymin" => ymin, "ymax" => ymax, "center_x" => center[0], "center_y" => center[1], 'x_size' => xsize.to_i, 'y_size' => ysize.to_i }

        end

end


##
# Extracts a tile..
def do_tile ( source, x,y,xsize,ysize,fl_name, edge=false)
        #s = "gdal_translate -srcwin #{x} #{y} #{xsize} #{ysize} #{source} #{name}.tif"
        #runner(s)
	s = "gdal_translate -a_nodata \"#{@no_data_out}\" -co COMPRESS=LZW -co TILED=YES  #{@bands_working} -srcwin #{x} #{y} #{xsize} #{ysize} #{source} #{fl_name}.tif"
       	runner(s)
       	add_overviews("#{fl_name}.tif")
       	
end

def chop ( source_image, set ) 
	image_info = Gdal.getextents(source_image)
	x = x_size = image_info['x_size']
	y = y_size = image_info['y_size']
	puts("Image is #{x}x#{y}")
	

	size=@tile_size

	tiddle_x = twiddle_y = 0
	tiddle_x = 1 if ( x_size%size != 0) 
	tiddle_y =  1 if ( y_size%size != 0)

	working_x = working_y = 0

	while (working_x < (x/size+tiddle_x) )
        	working_y = 0
        	while (working_y < (y/size+tiddle_y) )
			#name = source_image + "_#{working_x}_#{working_y}"
			name = @finaldir + "/" + @scene_id + set + sprintf("_tile_%d_%d", working_x, working_y)
                	if ( (working_y*size + size > y) || (working_x*size + size > x) )
                        	if ( (working_y*size + size > y) && (working_x*size + size > x) )
                                	do_tile (source_image, working_x*size, working_y*size, x-working_x*size, y-working_y*size, name,true) 
                        	else
                                if (working_x*size + size > x) 
                                        do_tile (source_image, working_x*size, working_y*size, x-working_x*size, size, name,true)
                                else
                                        do_tile (source_image, working_x*size, working_y*size, size, y-working_y*size, name,true)
                                end
                        end
                	else
                        	if ( working_x == 0 || working_y == 0 )
					do_tile (source_image, working_x*size, working_y*size, size, size,name,true)
				else
					do_tile (source_image, working_x*size, working_y*size, size, size,name)  
				end
                	end
                	working_y += 1
        	end
		working_x += 1
	end

end


@COMPRESS_OPS = ""

ARGV.each {|z|
	cfg = YAML.load(File.open(z))

  	##
  	# Save nodata file
  	cfg["ingest"]["nodata_out"] = cfg["ingest"]["nodata"] = cfg["ingest"]["nodata_in"]


	@compress = cfg["ingest"]["compress"]
	@tile_size = cfg["ingest"]["tile_size"].to_i
	ingest_dir = cfg["sv_metadata_basic"]["id"] + "_ingest"
	@finaldir = ingest_dir+"/tiles/"
	@no_data_in = cfg["ingest"]["nodata_in"]
	@no_data_out = cfg["ingest"]["nodata_out"]

	if ( ! cfg["data"]["bands"] )
		@bands_in =  cfg["ingest"]["bands_in"]
	else
		@bands_in =  " -b " + cfg["data"]["bands"].split(" ").join(" -b ")
	end

  	@bands_working = cfg["ingest"]["bands_working"]
	if ( cfg["ingest"]["s_srs"] )
  		@projection_in = cfg["ingest"]["s_srs"]
	end
	@scene_id = cfg["sv_metadata_basic"]["id"]
	@resampling ="-rcs"
  	#@debug = true

	if (!File.exists?(ingest_dir))
		Dir.mkdir( ingest_dir )
		Dir.mkdir( @finaldir)
	else
		puts("#{@finaldir} allready exists... perhaps you should deal with this first.")
		exit(-1)
	end

	set = 1
	pp  cfg["data"]
	
	x = File.dirname(z) + "/" + File.basename(z,".yml")+ "/"+ cfg["data"]["image_file"]
	
	ext = "." + x.split(".").last
	# Step 1 - make a temp directory to do work in..
	@workdir=  @scene_id+".working"

	while ( File.exists?(@workdir) )
		@workdir = @workdir + "x"
	end
	Dir.mkdir(@workdir)
	
	##
	# basic template for tile names - scene_id_projectiontag_x_y.tif
	working_name = @workdir + "/" + cfg["sv_metadata_basic"]["id"] + ".tif"

	##
	# Step 1 - convert mask to geotif...
	# 1.1 - convert mask pbm to tif, so gdal understands it..
	mask =  File.dirname(z) + "/"+ cfg["ingest"]["image_file_mask"][0]
	working_mask = @workdir + "/mask.tif"
	
	runner("pamtotiff #{mask} > #{@workdir}/mask.nongeo.tif")
	# 1.2 - make mask a geotif..
	runner("#{File.dirname(__FILE__)}/../copy_geo_info.rb -g #{x} -i #{@workdir}/mask.nongeo.tif -o #{working_mask}")

	##
        # Step 2 - convert to tiled bigtiff..
	x = to_bigtiff(x, working_name)

	##
	# Now - do the projections!
    	cfg["ingest"]["projections"].each {|proj| 
	
        	@projection_tag = proj["projection_tag"]
		@projection = proj["projection"]
        	source_projection = cfg["data"]["s_srs"]

	    	##
		# Step 3 - repo 
		y = do_repo(x,working_mask, @projection, source_projection, ".", @projection_tag)
		##
		# Step 4 - Split up into smaller files..
		chop(y,@projection_tag)

		 ##
		 # Step 5 - Scale to a small tif
		 scale (y,@projection, source_projection, proj["overview_res"] , ingest_dir+"/"+@scene_id+"_overview_"+@projection_tag)

		 ##
		 # Step 7 - generate tile outlines..
		 runner("gdaltindex #{ingest_dir}/#{@scene_id}#{@projection_tag}outlines.shp #{ingest_dir}/tiles/*#{@projection_tag}*.tif #{ingest_dir}/tiles/*#{@projection_tag}*.ecw")

		 ##
		 # Steo 8 - generate overview tile outlines...
	   	runner("gdaltindex #{ingest_dir}/#{@scene_id}#{@projection_tag}outlines_overview.shp #{ingest_dir+"/"+@scene_id+"_overview_"+@projection_tag+".tif"}")
        	proj["tiles"] = "#{ingest_dir}/#{@scene_id}#{@projection_tag}outlines.shp"
        	proj["tiles_overview"] = "#{ingest_dir}/#{@scene_id}#{@projection_tag}outlines_overview.shp"
        	proj["overview_data_tiles"] = ["#{ingest_dir+"/"+@scene_id+"_overview_"+@projection_tag+".tif"}"]
        	proj["data_tiles"] = Dir.glob("#{ingest_dir}/tiles/*#{@projection_tag}*.tif")
        	
      }

    ##
    #        # Step 6 - Clean up
    #
    runner("rm -rf #{@workdir} ")

		##
		# Step 8.1 copy TOC,md5,and,tar.gz file
		

		##
		# Step 9 - update yaml file..

		cfg["ingest"]["z_level"] = 0			#Update if and when kevin starting feeding these to me
  	cfg["ingest"]["bdl_layer"] =  "bdl_1_meter"     
		File.open(z, "w") { |r|  YAML.dump(cfg,r)  }

		##
		# Step xx - copy YAML file
		runner ("cp #{z} #{ingest_dir}/")
	
		set = set + 1
 }


