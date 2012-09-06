#!/usr/bin/env ruby 
require "rubygems"
require "pp"
require "fileutils"
require "yaml"


GOOGLE_MAX=20037508.3427891

def clip ( pt  )
        #pt.x = pt.x.round.to_f
        #pt.y = pt.y.round.to_f #+ ((pt.y - pt.y.round.to_f)*6).round.to_f/6.0
	#pt

        pt.x = pt.x.round.to_f + ((pt.x - pt.x.round.to_f)*2).round.to_f/2.0
        pt.y = pt.y.round.to_f + ((pt.y - pt.y.round.to_f)*2).round.to_f/2.0
	pt
end


def get_cords ( z )
	#geometry_ll:
	#  type: rectangle8
	#    upper_left_lon: 177.930292721204722
	#      upper_left_lat: 64.047918806750332
	#        mid_left_lon: 177.918186294267741
	#          mid_left_lat: 63.679209551481449
	#            lower_left_lon: 177.906427899748650
	#              lower_left_lat: 63.310480027366246
	#                upper_mid_lon: 179.026107480258105
	#                  upper_mid_lat: 64.036775410452805
	#                    lower_mid_lon: 178.974164584045013
	#                      lower_mid_lat: 63.299690130733175
	#                        upper_right_lon: -179.879416907664563
	#                          upper_right_lat: 64.017383117665815
	#                            mid_right_lon: -179.919955106341973
	#                              mid_right_lat: 63.649164154930411
	#                                lower_right_lon: -179.959330615949114
	#                                  lower_right_lat: 63.280912374153608
	#
	#
	pp z
	ll = Point.from_x_y(z["lower_left_lon"], z["lower_left_lat"])
	lr = Point.from_x_y(z["lower_right_lon"], z["lower_right_lat"])
        ul = Point.from_x_y(z["upper_left_lon"], z["upper_left_lat"])
        ur = Point.from_x_y(z["upper_right_lon"], z["upper_right_lat"])
	[clip(ul),clip(ll),clip(ur),clip(lr)]
end

def get_points( a, b)
	#puts("get_points #{a.x} to #{b.x}")
	#puts("get_points #{a.y} to #{b.y}")
	incs = 20.0
	x_delta = (b.x - a.x).to_f
	x_delta /= incs
	y_delta = (b.y - a.y).to_f
	y_delta /= incs
	
	points = []
	0.upto(incs.to_i-1) do |i|
		points << Point.from_x_y(a.x + x_delta*i.to_f, a.y + y_delta*i.to_f)
		#puts("#{i}: Point(#{points.last.x},#{points.last.y})")
	end

	points
end

def get_full_projection(x)
        info = `gdalinfo #{x}`.split("\n")
        i = 0
        while (!info[i].include?("PROJCS"))
         i += 1
        end
	ii = 0
	while (!info[i+ii].include?("GCP"))
         ii += 1
        end

	puts(info[i,ii])

	info[i,ii]
end

def get_info(x)
	cfg = YAML.load(`gdal_list_corners #{x}`) 
	cfg
end

def get_projection(x)
        info = `gdalinfo #{x}`.split("\n")
        i = 0
        while (!info[i].include?("DATUM"))
         i += 1
        end

	#e = 0
        #while (!info[i+e].include?("GCP"))
        # e += 1
        #end

	puts info[i,5]
	'GEOGCS["GCS_WGS_1984",' + info[i,5].join + ',PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]'
end

def warp_and_clip(source, basename, proj, tag,source_prj, res=0)
		puts("warp_and_clip(#{basename}, #{proj}, #{tag})")
		t_srs=" -s_srs #{source_prj}"
		tr=""
                tr= "-tr #{res} #{res}" if (res!=0)
                system("gdalwarp -srcnodata \"0 0 0\" -dstnodata \"0 0 0\" #{tr} -t_srs epsg:#{proj} -co TILED=YES -co COMPRESS=DEFLATE -rb #{source} #{basename}.#{tag}.tif")
		system("add_overviews.rb #{basename}.#{tag}.tif")
end


def warp_and_clip_ex(basename, proj, tag, min, max,res=0)
                puts("warp_and_clip(#{basename}, #{proj}, #{tag}, #{min.join(" ")}, #{max.join(" ")})")
		tr=""
		tr= "-tr #{res} #{res}" if (res!=0)

		if ((max[0].to_f - min[0].to_f) < res)
			puts("warp_and_clip: skipping, data would be too small")
			return
		end
		
                command = "gdalwarp #{tr} -te #{min[0]} #{min[1]} #{max[0]} #{max[1]} -t_srs epsg:#{proj} -co TILED=YES -co COMPRESS=DEFLATE -rc #{basename}.tif #{basename}.#{tag}.tmp.tif"
		puts("Running #{command}")
		system(command)
                system("ogr2ogr -t_srs epsg:#{proj} #{basename}.#{tag}.shp #{basename}.shp")
                system("gdal_rasterize -i -b 4 -burn 0 -l #{basename}.#{tag} #{basename}.#{tag}.shp  #{basename}.#{tag}.tmp.tif")
                system("gdal_translate -b 4 #{basename}.#{tag}.tmp.tif #{basename}.#{tag}.tmp.tif.mask")
                system("gdal_translate -b 1 -b 2 -b 3 #{basename}.#{tag}.tmp.tif #{basename}.#{tag}.tmp.tif.data")
                system("masker #{basename}.#{tag}.tmp.tif.data #{basename}.#{tag}.tmp.tif.mask #{basename}.#{tag}.tif")
                system("rm -v #{basename}.#{tag}.tmp.tif.data #{basename}.#{tag}.tmp.tif #{basename}.#{tag}.tmp.tif.mask")
		system("add_overviews.rb #{basename}.#{tag}.tif")
end

def gen_point ( gcp )
        " #{gcp["x"]},#{gcp["y"]} "
end


def mask (fl, mask, masked) 
	info = YAML.load(`gdal_list_corners #{fl}`)
	list = YAML.load(`get_gcp #{fl}`)
	box = "polygon "
	box += gen_point(list[0])
	box += gen_point(list[1])
	box += gen_point(list[2])
	box += gen_point(list[5])
	box += gen_point(list[8])
	box += gen_point(list[7])
	box += gen_point(list[6])
	box += gen_point(list[3])

	command = "convert -size #{info["width"]}x#{info["height"]} xc:none -stroke white -fill white -draw \"#{box}\" "
	command += mask
	system(command)
	system("masker #{fl} #{mask} #{masked}")
		
end


ARGV.each do |x|
	basename = File.basename(x,".gif").split(/[^A-Za-z0-9\.\_]+/).join("_")
	next if (File.exists?(basename))
	system("mkdir #{basename}")
	system("cp", "-v", x, basename +"/"+basename + ".gif")
	system("cp", "-v", File.basename(x, ".gif")+".map", basename +"/"+basename + ".map") 
	FileUtils.cd(basename) do 
		## Clip
		geo_projection = get_projection(File.basename(basename+".gif"))
		system("gdal_translate -expand rgba  #{basename}.gif #{basename}.tif")
		mask(basename+".tif", basename+".mask.tif", basename+".masked.tif")
		source_projection = get_full_projection("#{basename}.masked.tif")
		File.open("source.prj", "w") {|fd| fd.write(source_projection.join("\n"))}
		warp_and_clip(basename+".masked.tif", basename, "3338", "aa", "source.prj")	
		warp_and_clip(basename+".masked.tif",basename, "900913", "google", "source.prj")
		warp_and_clip(basename+".masked.tif",basename, "3572", "3572", "source.prj")
		warp_and_clip(basename+".masked.tif",basename, "4326", "geo", "source.prj")
	end
end
