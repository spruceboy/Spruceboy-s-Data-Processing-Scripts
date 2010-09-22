
ARGV.each do |item|
	File.open(File.basename(item).downcase+".job", "w") do |fd|
		fd.puts("#!/bin/bash")
		fd.puts("#PBS -q shared")
		fd.puts("#PBS -l walltime=10:00:00")
		fd.puts(". $HOME/.rvm/setup.sh")
		fd.puts(". $HOME/mapping_tools/setup.sh")
		fd.puts("cd #{item}")
		name = File.basename(item)
		fd.puts("ruby ~/cm/topo_processing/shade.rb $WORKDIR/dem/merged_aa.tif #{name}.combined.google.tif #{name}.shaded.google.tif epsg:900913")
		fd.puts("ruby ~/cm/topo_processing/shade.rb $WORKDIR/dem/merged_aa.tif #{name}.combined.aa.tif #{name}.shaded.aa.tif epsg:102006")
		fd.puts("ruby ~/cm/topo_processing/shade.rb $WORKDIR/dem/merged_aa.tif #{name}.combined.geo.tif #{name}.shaded.geo.tif epsg:4326")

		fd.puts("mv #{item} /workdir/users/jcable/topos/done/")
	end
end

