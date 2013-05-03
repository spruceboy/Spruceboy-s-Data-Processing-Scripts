#!/bin/env  ruby
# driver for conveyor
require "fileutils"


l0_file = ARGV[0]
target_dir = ARGV[1]



#make a link
system("cp -l -v #{l0_file} #{target_dir}")

FileUtils.cd(target_dir) do
	if ( File.basename(l0_file)[0] == "a")
		system("do_aqua.rb #{File.basename(l0_file)}")
	else
		system("do_terra.rb #{File.basename(l0_file)}")
	end
	system("rm -v #{File.basename(l0_file)}")
end

File.open(target_dir + "/" + File.basename(l0_file, ".zero.gz") + ".done", "w") {|fd| fd.puts("Done.")}

