#!/bin/env  ruby
require "fileutils"



ARGV.each do |item|
	target = File.basename(item)
	system("scp -c arcfour #{item}.msk #{item} webdev@maybe.x.gina.alaska.edu:/www/realtime/apps/data_natural_color/#{target[3,4]}")
end
