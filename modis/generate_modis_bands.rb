#!/usr/bin/env ruby

require "trollop"

projection_confs = { 
	"alaska_albers" =>{
		"bbox" => { 
				"xmax"=>3000000.0,
				"ymax"=>3000000.0,
				"xmin"=>-3000000.0,
				"ymin"=>-1000000.0
			},
		"def" => "0.0 0.0 55.0 65.0 -154.0 50.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0",
		"type" =>  "ALBERS"
		},
        "alaska_polar" =>{
                "bbox" => {
                                "xmax"=>3500000.0,
                                "ymax"=>500000.0,
                                "xmin"=>-3500000.0,
                                "ymin"=>-6000000.0
                        },
                "def" => "0.0 0.0 0.0 0.0 -150.0 90.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0",
                "type" =>  "LAMAZ"
                }
}


#INPUT_FILENAME = /hub/scratch/jcable/final_test/t1.12242.2018/t1.20120830.2018.cal250.hdf
#
#GEOLOCATION_FILENAME = /hub/scratch/jcable/final_test/t1.12242.2018/t1.20120830.2018.geo.hdf
#
#INPUT_SDS_NAME = EV_250_RefSB, 1
#
#OUTPUT_SPATIAL_SUBSET_TYPE = PROJ_COORDS
#OUTPUT_SPACE_UPPER_LEFT_CORNER (X Y) = -3500000.0 500000.0
#OUTPUT_SPACE_LOWER_RIGHT_CORNER (X Y) = 3500000.0 -6000000.0
#
#OUTPUT_FILENAME = /hub/scratch/jcable/final_test/out
#OUTPUT_FILE_FORMAT = GEOTIFF_FMT
#
#KERNEL_TYPE (CC/BI/NN) = BI
#
#OUTPUT_PROJECTION_NUMBER = LAMAZ
#
#OUTPUT_PROJECTION_PARAMETER = 0.0 0.0 0.0 0.0 -150.0 90.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
#
#OUTPUT_PROJECTION_SPHERE = 8
#
#OUTPUT_DATA_TYPE = UINT16
#
#OUTPUT_PIXEL_SIZE = 250
#


##
# Builds a prm file (projection parm file) for MRTSwath.
# Spaces/newlines might be important, not clear, so keep them. 
def make_prm (infile,geofile,outfile,sds, conf, pixel_size)

	s = "\n"
	s+= "INPUT_FILENAME = #{infile}\n"
	s+= "\n"
	s+= "GEOLOCATION_FILENAME = #{geofile}\n" 
	s+= "\n"
	s+= "INPUT_SDS_NAME =  #{sds}\n"
	s+= "\n"
	s+= "OUTPUT_SPATIAL_SUBSET_TYPE = PROJ_COORDS\n"
	s+= "OUTPUT_SPACE_UPPER_LEFT_CORNER (X Y) = #{conf["bbox"]["xmin"]} #{conf["bbox"]["ymax"]}\n"
	s+= "OUTPUT_SPACE_LOWER_RIGHT_CORNER (X Y) = #{conf["bbox"]["xmax"]} #{conf["bbox"]["ymin"]}\n"
	s+= "\n"
	s+= "OUTPUT_FILENAME = #{outfile}\n"
	s+= "OUTPUT_FILE_FORMAT = GEOTIFF_FMT\n"
	s+= "\n"
	s+= "KERNEL_TYPE (CC/BI/NN) = NN\n"
	s+= "\n"
	s+= "OUTPUT_PROJECTION_NUMBER = #{conf["type"]}\n"
	s+= "\n"
	s+= "OUTPUT_PROJECTION_PARAMETER = #{conf["def"]}\n"
	s+= "\n"
	s+= "OUTPUT_PROJECTION_SPHERE = 8\n"  	#WGS84
	s+= "\n"
	s+= "OUTPUT_PIXEL_SIZE = #{pixel_size}\n"
	
	return s
end



##
# Does ATM correction (fake I think) on modis
def calibrate (hdf_dir, outfile_base )
	hdf_1k = Dir.glob(hdf_dir + "/MOD021KM*.hdf")
	hdf_hk = Dir.glob(hdf_dir + "/MOD02HKM*.hdf")
	hdf_qk = Dir.glob(hdf_dir + "/MOD02QKM*.hdf")

	puts hdf_1k.join
	raise ("ERROR:calibrate found more/less than one MOD021KM file") if ( hdf_1k.length != 1)
        raise ("ERROR:calibrate found more/less than one MOD021HM file") if ( hdf_hk.length != 1)
        raise ("ERROR:calibrate found more/less than one MOD021QM file") if ( hdf_qk.length != 1)
	hdf_1k= hdf_1k.first
       	hdf_hk= hdf_hk.first
       	hdf_qk= hdf_qk.first

	system("crefl -f -v -1km #{hdf_hk} #{hdf_qk} #{hdf_1k} -of=#{outfile_base}.crefl.1km.hdf")
	system("crefl -f -v -500m #{hdf_hk} #{hdf_qk} #{hdf_1k} -of=#{outfile_base}.crefl.hkm.hdf")
	system("crefl -f -v -250m #{hdf_hk} #{hdf_qk} #{hdf_1k} -of=#{outfile_base}.crefl.qkm.hdf")
	puts("INFO: Atm corrected.")
end



##
# Grids and projects data using MrtSwath
def project_data( infile,geofile,outfile,sds, conf, pixel_size, expected_number_of_files)
	File.open("mrtswath.prm", "w") {|fd| fd.puts(make_prm(infile,geofile,outfile,sds, conf, pixel_size))}
	system("swath2grid -pf=./mrtswath.prm")
	files = Dir.glob(outfile+"*")
	puts("INFO:project generated #{files.count} files.")
	raise("ERROR: project generated the incorrect number of files..") if (expected_number_of_files && expected_number_of_files != files.length)
end



## Command line parsing action..
parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
  This util generates a bunch of bands from viirs data using pytroll, the combines them into something useful.  

Usage:
      make_modis_bands.rb [options] basename
Where basename is the path and root of the modis l1b data and [options] is:
EOS

  opt :verbrose, "Maxium Verbrosity.", :short => "V"
  opt :area, "Area to be used", :default => "alaska_albers"
end

opts = Trollop::with_standard_exception_handling(parser) do
  o = parser.parse ARGV
  raise Trollop::HelpNeeded if ARGV.length == 0 # show help screen
  o
end


basename = ARGV.first

full_bands = 'EV_500_RefSB, 1, 1, 1, 1, 1; EV_500_RefSB_Uncert_Indexes, 1, 1, 1, 1, 1; EV_250_Aggr500_RefSB, 1, 1; EV_250_Aggr500_RefSB_Uncert_Indexes, 1, 1; EV_250_Aggr500_RefSB_Samples_Used, 1, 1'

puts projection_confs.keys
proj_conf = projection_confs[opts[:area]]

project_data(basename + ".cal250.hdf", basename + ".geo.hdf", basename + "." + opts[:area] + ".250m", "EV_250_RefSB, 1, 1", proj_conf, 250, nil)
project_data(basename + ".cal500.hdf", basename + ".geo.hdf", basename + "." + opts[:area] + ".500m", full_bands, proj_conf, 500, nil)
calibrate(File.dirname(basename), basename + ".corrected")
project_data(basename + ".corrected.crefl.qkm.hdf", basename + ".geo.hdf", basename + "." + opts[:area] +".250m", "CorrRefl_01", proj_conf, 250, nil)
project_data(basename + ".corrected.crefl.hkm.hdf", basename + ".geo.hdf", basename + "." + opts[:area] + ".500m", "CorrRefl_01; CorrRefl_03; CorrRefl_04", proj_conf, 500, nil)
