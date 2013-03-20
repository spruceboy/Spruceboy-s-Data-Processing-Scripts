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

#should be busted out into a seperate config file..
modis_band_mapper = {
		"ATM1"=>".250m_CorrRefl_01.tif", 
		"ATM3"=>".500m_CorrRefl_03.tif", 
		"8"=>".1000m_EV_1KM_RefSB_b0.tif", 
		"11"=>".1000m_EV_1KM_RefSB_b3.tif", 
		"14L"=>".1000m_EV_1KM_RefSB_b7.tif", 
		"16"=>".1000m_EV_1KM_RefSB_b10.tif", 
		"12"=>".1000m_EV_1KM_RefSB_b4.tif", 
		"14H"=>".1000m_EV_1KM_RefSB_b8.tif", 
		"26S"=>".1000m_EV_Band26.tif", 
		"10"=>".1000m_EV_1KM_RefSB_b2.tif", 
		"13L"=>".1000m_EV_1KM_RefSB_b5.tif", 
		"15"=>".1000m_EV_1KM_RefSB_b9.tif", 
		"1"=>".250m_EV_250_RefSB_b0.tif", 
		"2"=>".250m_EV_250_RefSB_b1.tif", 
		"3"=>".500m_EV_500_RefSB_b0.tif", 
		"4"=>".500m_EV_500_RefSB_b1.tif", 
		"5"=>".500m_EV_500_RefSB_b2.tif", 
		"6"=>".500m_EV_500_RefSB_b3.tif",
 		"7"=>".500m_EV_500_RefSB_b4.tif",
		"1_500m"=>".500m_EV_250_Aggr500_RefSB_b0.tif", 
		"2_500m"=>".500m_EV_250_Aggr500_RefSB_b1.tif", 
		"ATM1_500"=>".500m_CorrRefl_01.tif", 
		"ATM4"=>".500m_CorrRefl_04.tif", 
		"9"=>".1000m_EV_1KM_RefSB_b1.tif", 
		"13H"=>".1000m_EV_1KM_RefSB_b6.tif", 
		"17"=>".1000m_EV_1KM_RefSB_b11.tif", 
		"18"=>".1000m_EV_1KM_RefSB_b12.tif", 
		"19"=>".1000m_EV_1KM_RefSB_b13.tif", 
		"26"=>".1000m_EV_1KM_RefSB_b14.tif", 
		"20"=>".1000m_EV_1KM_Emissive_b0.tif", 
		"21"=>".1000m_EV_1KM_Emissive_b1.tif", 
		"22"=>".1000m_EV_1KM_Emissive_b2.tif",
 		"23"=>".1000m_EV_1KM_Emissive_b3.tif", 
		"24"=>".1000m_EV_1KM_Emissive_b4.tif", 
		"25"=>".1000m_EV_1KM_Emissive_b5.tif", 
		"27"=>".1000m_EV_1KM_Emissive_b6.tif", 
		"28"=>".1000m_EV_1KM_Emissive_b7.tif", 
		"29"=>".1000m_EV_1KM_Emissive_b8.tif", 
		"30"=>".1000m_EV_1KM_Emissive_b9.tif", 
		"31"=>".1000m_EV_1KM_Emissive_b10.tif", 
		"32"=>".1000m_EV_1KM_Emissive_b11.tif", 
		"33"=>".1000m_EV_1KM_Emissive_b12.tif", 
		"34"=>".1000m_EV_1KM_Emissive_b13.tif", 
		"35"=>".1000m_EV_1KM_Emissive_b14.tif", 
		"36"=>".1000m_EV_1KM_Emissive_b15.tif"}


#Cleans up tifs and renames them to something useful
def reformat( basename, modis_band_mapper ) 
	modis_band_mapper.keys.each do |band|
		puts("INFO: reformating Band #{band}..")
		if ( File.exists?("#{basename}#{modis_band_mapper[band]}"))
			system("gdal_translate -co COMPRESS=DEFLATE -co TILED=YES " + 
				"#{basename}#{modis_band_mapper[band]} #{basename}.band_#{band}.tif")
		end
		system("rm", "-v", "#{basename}#{modis_band_mapper[band]}")
	end
end

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

	system("crefl --verbose --1km #{hdf_hk} #{hdf_qk} #{hdf_1k} --of=#{outfile_base}.crefl.1km.hdf")
	system("crefl --verbose --500m #{hdf_hk} #{hdf_qk} #{hdf_1k} --of=#{outfile_base}.crefl.hkm.hdf")
	system("crefl --verbose  #{hdf_hk} #{hdf_qk} #{hdf_1k} --of=#{outfile_base}.crefl.qkm.hdf")
	puts("INFO: Atm corrected.")
end



##
# Grids and projects data using MrtSwath
def project_data( infile,geofile,outfile,sds, conf, pixel_size, expected_number_of_files)
	prm_file=File.basename(infile) +".mrtswath.prm"
	File.open(prm_file, "w") {|fd| fd.puts(make_prm(infile,geofile,outfile,sds, conf, pixel_size))}
	system("swath2grid -pf=./#{prm_file}")
	files = Dir.glob(outfile+"*")
	system("rm #{prm_file}")
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

#full_bands = 'EV_500_RefSB, 1, 1, 1, 1, 1; EV_500_RefSB_Uncert_Indexes, 1, 1, 1, 1, 1; EV_250_Aggr500_RefSB, 1, 1; EV_250_Aggr500_RefSB_Uncert_Indexes, 1, 1; EV_250_Aggr500_RefSB_Samples_Used, 1, 1'
full_bands = "EV_500_RefSB, 1, 1, 1, 1, 1; EV_250_Aggr500_RefSB, 1, 1; EV_250_Aggr500_RefSB_Uncert_Indexes, 1, 1; EV_250_Aggr500_RefSB_Samples_Used, 1, 1"

onek_bands = 'EV_1KM_RefSB, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1; EV_1KM_Emissive, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1; EV_Band26'

puts projection_confs.keys
proj_conf = projection_confs[opts[:area]]

if ( File.exists?(basename + ".cal250.hdf"))
	puts("Info: Daytime pass.")
	project_data(basename + ".cal250.hdf", basename + ".geo.hdf", basename + "." + opts[:area] + ".250m", "EV_250_RefSB, 1, 1", proj_conf, 250, nil)
	project_data(basename + ".cal500.hdf", basename + ".geo.hdf", basename + "." + opts[:area] + ".500m", full_bands, proj_conf, 500, nil)
	calibrate(File.dirname(basename), basename + ".corrected")
	project_data(basename + ".corrected.crefl.qkm.hdf", basename + ".geo.hdf", basename + "." + opts[:area] +".250m", "CorrRefl_01", proj_conf, 250, nil)
	project_data(basename + ".corrected.crefl.hkm.hdf", basename + ".geo.hdf", basename + "." + opts[:area] + ".500m", "CorrRefl_01; CorrRefl_03; CorrRefl_04", proj_conf, 500, nil)

else
	puts("Info: Nightime pass.")
end

project_data(basename + ".cal1000.hdf", basename + ".geo.hdf", basename + "." + opts[:area] + ".1000m", onek_bands, proj_conf, 1000, nil)

reformat(basename + "." + opts[:area], modis_band_mapper)


