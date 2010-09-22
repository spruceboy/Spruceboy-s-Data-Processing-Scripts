
ARGV.each do |item|
	File.open(File.basename(item).downcase+".job", "w") do |fd|
		fd.puts("#!/bin/bash")
		fd.puts("#PBS -q shared")
		fd.puts("#PBS -l walltime=10:00:00")
		fd.puts(". $HOME/.rvm/setup.sh")
		fd.puts(". $HOME/mapping_tools/setup.sh")
		fd.puts("cd #{item}")
		fd.puts("ruby /u1/uaf/jcable/cm/topo_processing/do_on_packman.rb #{item}/*-srcdata.tar.gz")
		fd.puts("mv #{item} /workdir/users/jcable/topos/done/")
	end
end

