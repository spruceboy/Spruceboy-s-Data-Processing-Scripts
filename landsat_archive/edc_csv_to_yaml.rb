#!/usr/bin/env ruby
#
# EDC CSV to YAML - hurrah..?
require "pp"
require "yaml"


def chop_up_csv (i)
  return i.split("\",\"").collect do |ii|
    i=ii.split("\"")
    if (i.length==1)
      i.first
    else
      i[1]
    end
  end
end

ARGV.each do |item|
  stuffs=[]
  keys = nil
  File.open(item).each_line do |z|
      if (!keys)
        keys = chop_up_csv(z)
      else
        bits = chop_up_csv(z)
        row={}
        keys.each_index {|i| row[keys[i]] = bits[i]}
        stuffs << row
      end
  end
  File.open(item+".yml", "w"){|fd| YAML.dump(stuffs, fd)}
end


