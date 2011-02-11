#!/usr/bin/env ruby
#
require "pp"
require "yaml"

def compare (x,y)
  return 1 if (x["Acquisition Date:"] > y["Acquisition Date:"])
   return -1 if (x["Acquisition Date:"] < y["Acquisition Date:"])
   return 1 if (x["Row:"] > y["Row:"] )
   return -1 if (x["Row:"] < y["Row:"] )
   return 0
end

ARGV.each do |cfg|
  items = File.open(cfg){|fd| YAML.load(fd)}
  i = Math.sqrt(items.length).to_i
  items.sort! {|x,y| compare(x,y)}
  items=items[0,100]
  count = 0
  0.upto(items.length-2) do |index| 
        start_thumb = "thumbs/#{items[index]["entity_id"]}.jpg"
        end_thumb = "thumbs/#{items[index+1]["entity_id"]}.jpg"
        system("montage #{start_thumb} #{end_thumb} -mode Concatenate  -tile 1x2 foo.png")
	0.upto(748/10) do |y_inc|
		frame = sprintf("frames/frame_%010d.jpg", count)
		label = "Landsat 5: #{items[index]["Acquisition Date:"]} path #{items[index]["Path:"]} row #{items[index]["Row:"]}"
		system("convert #{start_thumb} foo.png -geometry +0-#{y_inc*10} -composite  -pointsize 24 -fill white  -undercolor '#00000040'  -gravity SouthWest -annotate +5+5 '#{label}' #{frame}")
		count += 1
	end
  end
end


