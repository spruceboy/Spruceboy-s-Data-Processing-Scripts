#!/usr/bin/env ruby
require "pp"
list = {}


ARGV.each do |i|
  bits = File.basename(i, "-srcdata.tar.gz").match(/USGS\.DRG\.(\d+\w+)\.([A-Z\.]+)(\.\w\.\d+)+/).to_a
  s = bits[1] + "_" + bits[2]
  if (s == nil)
    puts ("Problem with #{i}")
    exit
  end
  list[s]=[] if (!list[s])
  list[s] << i
end


#check that the number of files is reasonable..
list.keys.each do |x|
  if (list[x].length > 32)
    puts("problem with #{x}")
    pp list[x]
    puts("quiting..")
    exit(-1)
  end
end

#sort..
list.keys.each do |x|
  puts("Doing \"#{x}\"")
  system("mkdir", x)
  list[x].each {|i| system("ln","-v", i, x + "/"+File.basename(i))}
end