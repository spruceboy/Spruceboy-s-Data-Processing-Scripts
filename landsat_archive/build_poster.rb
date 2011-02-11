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
  count = 0
  0.upto(i-1) do |col|
    0.upto(i-1) do |row|
      thumb = "thumbs/#{items[count]["entity_id"]}.jpg"
      target = sprintf("tiles/tile_%02d_%02d.big.pnm",col, row)
      next if (File.exists?(target))
      puts("jpegtopnm #{thumb} > #{target}")
      system("jpegtopnm #{thumb} | pamscale -xsize=100 -ysize=100 >  #{target}")
      count += 1
    end
  end
  pp items[0]
  pp items[1]
  pp items[2]
end


