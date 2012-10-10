#!/usr/bin/env ruby 
require "rubygems"
require "geo_ruby"
include GeoRuby
include GeoRuby::SimpleFeatures
include GeoRuby::Shp4r
require "pp"
require "fileutils"
require "yaml"


GOOGLE_MAX=20037508.3427891

def clip ( pt  )
        pt.x = pt.x.round.to_f + ((pt.x - pt.x.round.to_f)*2).round.to_f/2.0
        pt.y = pt.y.round.to_f + ((pt.y - pt.y.round.to_f)*6).round.to_f/6.0
	pt
end


def gen_point ( gcp )
	 Point.from_x_y(gcp["gx"], gcp["gy"])
end

def get_outline (fl)
	list = YAML.load(`get_gcp #{fl}`)
	box = []
        box += [gen_point(list[0])]
        box += [gen_point(list[1])]
        box += [gen_point(list[2])]
        box += [gen_point(list[5])]
        box += [gen_point(list[8])]
        box += [gen_point(list[7])]
        box += [gen_point(list[6])]
        box += [gen_point(list[3])]
	box += [gen_point(list[0])]
	return box
end

def get_points( a, b)
	puts("get_points #{a.x} to #{b.x}")
	puts("get_points #{a.y} to #{b.y}")
	incs = 10.0
	x_delta = (b.x - a.x).to_f
	x_delta /= incs
	y_delta = (b.y - a.y).to_f
	y_delta /= incs
	
	points = []
	0.upto(incs.to_i-1) do |i|
		points << Point.from_x_y(a.x + x_delta*i.to_f, a.y + y_delta*i.to_f)
		puts("#{i}: Point(#{points.last.x},#{points.last.y})")
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

def warp_and_clip(basename, proj, tag)
		puts("warp_and_clip(#{basename}, #{proj}, #{tag})")
                system("gdalwarp -t_srs epsg:#{proj} -co TILED=YES -co COMPRESS=DEFLATE -rb #{basename}.tif #{basename}.#{tag}.tmp.tif")
                system("ogr2ogr -t_srs epsg:#{proj} #{basename}.#{tag}.shp #{basename}.msk.shp")
                system("gdal_rasterize -i -b 4 -burn 0 -l #{basename}.#{tag} #{basename}.#{tag}.shp  #{basename}.#{tag}.tmp.tif")
		system("gdal_translate -b 4 #{basename}.#{tag}.tmp.tif #{basename}.#{tag}.tmp.tif.mask")
		system("gdal_translate -b 1 -b 2 -b 3 #{basename}.#{tag}.tmp.tif #{basename}.#{tag}.tmp.tif.data")
		system("masker #{basename}.#{tag}.tmp.tif.data #{basename}.#{tag}.tmp.tif.mask #{basename}.#{tag}.tif")

		[".shx", ".prj", ".dbf", ".shp"].each {|st| system("rm -vf #{basename}.#{tag}#{st}")}

		system("rm -v #{basename}.#{tag}.tmp.*")
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





ARGV.each do |x|
	basename = File.basename(x,".gif").split(/[^A-Za-z0-9\.\_]+/).join("_")
	next if (File.exists?(basename))
	system("mkdir #{basename}")
	system("cp", "-v", x, basename +"/"+basename + ".gif")
	system("cp", "-v", File.basename(x, ".gif")+".map", basename +"/"+basename + ".map") 
	FileUtils.cd(basename) do 
		geo_projection = get_projection(File.basename(basename+".gif"))
		system("gdal_translate -expand rgba  #{basename}.gif #{basename}.tif")

		#make a shp file of the outline
		source_projection = get_full_projection("#{basename}.tif")
		File.open("source.prj", "w") {|fd| fd.write(source_projection.join("\n"))}
		points = get_outline(basename+".gif")
		poly = Polygon.from_points([points])

		shpfile = ShpFile.create(basename+'.shp',ShpType::POLYGON,[Dbf::Field.new("Nothing","C",10)])
        	shpfile.transaction do |tr|
                	tr.add(ShpRecord.new(poly,'Nothing' => "YES"))
        	end
        	shpfile.close

		File.open(basename+'.prj', "w") {|fd| fd.puts(source_projection) }

		#now make a shapefile with the split up outline..
		system("ogr2ogr -t_srs epsg:4326 "  + 
			"#{basename}.tmp.shp #{basename}.shp")
		system("ogr2ogr -t_srs epsg:4326 -segmentize 0.001 "  + 
                        "#{basename}.msk.shp #{basename}.tmp.shp")
		#["3572", "3573", "3574", "3575", "3576", "3338", "4326", "900913"]
		["3572", "3573", "3574", "3575", "3576", "4326", "900913"].each do |proj|
			warp_and_clip(basename, proj, proj)
		end

		system("rm -v #{basename}.msk.*  #{basename}.tmp.*")
	
		[".tif", ".shx", ".prj", ".dbf", ".shp"].each {|st| system("rm -v #{basename}#{st}")}
	end
end
