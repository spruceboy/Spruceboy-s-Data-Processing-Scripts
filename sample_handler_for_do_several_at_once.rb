#!/usr/bin/env ruby
#Example handler file..

infile = ARGV.first
outfile = File.basename(infile, ".tif") + ".jpg.tif"
system("~/cm/processing_scripts/rgb_to_jpeg_tif.rb  --internal-mask #{infile} #{outfile}")

