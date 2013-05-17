#!/bin/env  ruby
require "fileutils"


l1_dir = ARGV[0]

target_dir = ARGV[1]

FileUtils.cd(l1_dir) do
	x = Dir.glob("?1.????????.????.cal1000.hdf")
	raise ("Too many 1k hdf files found!") if ( x.length > 1)
	raise ("No 1k hdf files found!") if ( x.length == 0 )

	basename = File.basename(x.first, ".cal1000.hdf")
	target = target_dir + "/" +  basename
	system("mkdir -v #{target}")
	[".geo.hdf", ".cal1000.hdf", ".cal250.hdf", ".cal500.hdf"].each do |z|
		z = basename + z
		system("cp -l -v #{z} #{target}") if (File.exists?(z))
	end
	
	system("cp -l -v MOD02* #{target}")

	system("generate_modis_bands.rb #{target}/#{basename}")
	
	File.open(target +".done", "w") {|fd| fd.puts("Done.")}
end
