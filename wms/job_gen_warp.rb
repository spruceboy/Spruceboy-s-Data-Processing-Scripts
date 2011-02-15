
ARGV.each do |item|
	File.open(File.basename(item).downcase+".job", "w") do |fd|
		name = File.basename(item)
		fd.puts("#!/bin/bash")
		fd.puts("#PBS -q shared")
		fd.puts("#PBS -l walltime=20:00:00")	
		fd.puts("#PBS -r n")
		fd.puts(". $HOME/.rvm/setup.sh")
		fd.puts(". /home/local/unsupported/UAFGINA/mapping_tool_builds/2011_02_14/setup.sh")
		fd.puts("export GDAL_CACHEMAX=1024")
                fd.puts("cd #{item}")
		fd.puts("cp ~/cm/wms/template.yml .")
                fd.puts("echo $HOSTNAME $$ start:`date` >> node")
                fd.puts("echo $PBS_JOBID >> job_id")
                fd.puts("echo $HOSTNAME > $HOSTNAME")
                fd.puts("ruby ~/cm/wms/warper.rb *.tif ")
		fd.puts("mv #{item} /wrkdir/jcable/overviews/done/")
	end
end

