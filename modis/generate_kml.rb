#!/usr/bin/env ruby
require "trollop"
require "fileutils"


#Parses date of the format:
#PP.YYYYMMDD.HHMM
#like : t1.20121129.2042
def modis_date( base )
	#t1.20121129.2042
	bits = base.split(".")
	date = bits[1]
	time = bits[2]
	#tm = Time.utc(2000 + bits[1].to_i) + (bits[2].to_i-1)*24*60*60 + (bits[3][0,2].to_i)*60*60 + (bits[3][2,2].to_i)*60
	tm = Time.utc(date[0,4], date[4,2], date[6,2], time[0,2], time[2,2])
	return tm
end

def npp_date ( base )
end


def get_description (fl)
	date = parse_date ( fl )
	
	time_sm = date.strftime("%B %d, %Y")

 	base = File.basename(fl)
	
        case base.split(".").first
                when "t1"
			return (" Terra-1 data acquired on #{time_sm}. ")
		when "a1"
			return (" Aqua-1 data acquired on #{time_sm}. ")
                when "npp"
			return (" NPP data acquired on #{time_sm}. ")
                else
                        raise ("Bad filename, not Modis or NPP -> \"#{base}\"")
        end
end

def mk_path(path)
    splits = path.split("/")
    start = splits.first
    splits.delete_at(0)
    splits.each do |x|
      start += "/" + x
      if ( !File.exists?(start))
        puts("mk_path: making #{start}")
        begin
          Dir.mkdir(start)
        rescue => e
            puts("mk_path: Something when wrong, probibly allready there..#{e.to_s}")
        end
      end
    end
  end



def parse_date ( fl )
	base = File.basename(fl)
	
	case base.split(".").first
		when "t1", "a1"
			return (modis_date(base))
		when "npp" 
			return (npp_date(base))
		else
			raise ("Bad filename, not Modis or NPP -> \"#{base}\"")
	end
end



parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
  This util crunchs out a kml set for a modis or npp image.

Usage: 
        generate_kml.rb [options] <infile> <outdir>
where [options] is:
EOS
  opt :tr_res, "Target Resolution", :default => 0.004
  opt :stretch, "Stretch to be used, be sure to quote!", :default => "-percentile-range 0.02 0.98"
end

opts = Trollop::with_standard_exception_handling(parser) do
  o = parser.parse ARGV
  raise Trollop::HelpNeeded if ARGV.length != 2 # show help screen
  o
end


in_file = ARGV[0]
out_dir = ARGV[1]


bits = File.basename(in_file).split(".")
type = bits.first
date = parse_date(in_file)


location = type + "/" + date.strftime("%Y/%j") + "/" + bits[0,2].join(".") + "." + bits[2].split("_").first + "/" + bits[0,3].join(".")
out_dir += "/" + location

if ( File.exists?("#{out_dir}/#{bits[0,3].join(".")}.kml"))
	puts("INFO: Allready done. ")
	exit(0)
end

puts "INFO: using #{out_dir}"

#create paths..
mk_path(out_dir)

#In case the vrt is laying around..
system("rm -v #{out_dir}/4326.vrt") if (File.exists?("#{out_dir}/4326.vrt"))

#build vrt..
system("gdalwarp -tr #{opts[:tr_res]} #{opts[:tr_res]} -srcnodata \"0 0 0\" -dstnodata \"0 0 0\" -rb -wo SOURCE_EXTRA=128 -t_srs epsg:4326 -of VRT #{in_file} #{out_dir}/4326.vrt")

#build kml..
system("#{File.dirname(__FILE__)}/gdal2tiles.py -t #{bits[0,3].join(".")} -D \"#{get_description(in_file)}\"  -d #{date.to_i} -k -p geodetic -a 0 -u http://realtime.gina.alaska.edu/kml/#{File.dirname(location)} #{out_dir}/4326.vrt #{out_dir}")

#rename kml
system("mv #{out_dir}/doc.kml #{out_dir}/#{bits[0,3].join(".")}.kml")


#cleanup
system("rm -v  #{out_dir}/4326.vrt #{out_dir}/*html")

