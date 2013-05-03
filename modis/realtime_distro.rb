#!/bin/env  ruby
require "fileutils"


item=ARGV.first

FileUtils.cd(File.dirname(item)) do
	target = File.basename(item, ".tif") + ".jpg.tif"
	system("to_jpeg_tif.rb #{item} #{target}")
	system("scp #{target} #{target}.msk free.gina.alaska.edu:/www/realtime/apps/data_natural_color/#{target[3,4]}")
end
