#!/usr/local/bin/ruby


require "pp"
require "cgi"
require "rubygems"
require "xmlsimple"
require 'yaml'

####
# xml template..

network_link_example = {
                "name"=>["Firepoints"],
                "visibility"=>["1"],
                "refreshMode"=>["onRegion"],
                "Link"=>[{"href"=>["fillmeout"]}],
                "description"=>["Fill me out"],
                "LookAt"=>[{"latitude"=>[{"type"=>"float", "content"=>"63.5016291899263"}],
                    "altitude"=>[{"type"=>"integer", "content"=>"0"}],
                    "heading"=>[{"type"=>"float", "content"=>"0.93984811848743"}],
                    "range"=>[{"type"=>"float", "content"=>"2681756.27280516"}],
                    "tilt"=>[{"type"=>"integer", "content"=>"0"}],
                    "longitude"=>[{"type"=>"float", "content"=>"-147.453879357521"}]}]}
                    
xml_template_root = {
        "Document"=>[{"name"=>["Sample KMLs"],
            "NetworkLink"=>[],
            "LookAt"=>[{"latitude"=>["63.50162918992634"],
                        "altitude"=>["0"],
                        "heading"=>["0.9398481184874297"],
                        "tilt"=>["7.676719711599282e-15"],
                        "range"=>["2681756.272805156"],
                        "longitude"=>["-147.4538793575206"]}],
            "open"=>["1"]}],
        "xmlns"=>"http://earth.google.com/kml/2.1"}


def modis_date( base )
        bits = base.split(".")
        date = bits[1]
        time = bits[2]
 	tm = Time.utc(2000 + bits[1].to_i) + (bits[2].to_i-1)*24*60*60 + (bits[3][0,2].to_i)*60*60 + (bits[3][2,2].to_i)*60
        tm = Time.utc(date[0,4], date[4,2], date[6,2], time[0,2], time[2,2])
        return tm
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


        
# fl is like: 20050627.2127.t1.250m.jpg
def GetDateOfFile ( fl )
  dt = parse_date(fl)
  return ( dt.getlocal().strftime("%B %d, %Y at %I:%M %p %Z"));
end

# fl is like: 20050627.2127.t1.250m.jpg
def GetPlatformOfFile ( fl )
  platforms = { "a1" => "AQUA-1", "t1" => "TERRA-1", "npp" => "NPP"}
  
  x = File.basename(fl).split(".").first
  puts x
  return platforms[x] if ( platforms[x])
  return "unknown"
end

def GetBandsOfFile (fl)
  bands = { "7_2_1_500m_1" => "bands 7,2,1 enhanced with band 1", 
		"2_6_1_500m_1" => "bands 2,6,1 enhanced with band 1",
		"3_6_7" => "bands 3,6, and 7", 
		"ATM1_500_ATM4_ATM3_ATM1" => "bands 1, 4, 3 enhanced with band 1",
		"23" => "thermal band 23" }
  x = File.basename(fl).split(".")[-2].split("_")[1,10000].join("_")
  puts x
  return bands[x] if ( bands[x])
  return "unknown bands"
end

        
        
        
    list = Dir.glob("/hub/raid/kml/*/*/*/*/*/*.kml")
    list.sort!
    list = list.reverse[0,15]


    list.each_index do |i|
	puts list[i]
	next if (File.basename(list[i]) == "doc.kml")
	url = "http://realtime.gina.alaska.edu/" + list[i].split("/")[3,1000].join("/")
	puts url
        network_link = network_link_example.dup
        network_link["name"] = [File.basename(list[i], "kml")]
        network_link["Link"]=[{"href"=>[url]}]
        network_link["description"]=["Modis pass from #{GetPlatformOfFile(list[i])} received on #{GetDateOfFile(list[i])}, composed of #{GetBandsOfFile(list[i])}"]
        xml_template_root["Document"][0]["NetworkLink"] << network_link
        network_link["visibility"]=["0"] if ( i > 2)
    end
    File.open(ARGV.first, "w") {|fd| fd.puts(XmlSimple.xml_out(xml_template_root,  { "rootname" => 'kml'}))}
