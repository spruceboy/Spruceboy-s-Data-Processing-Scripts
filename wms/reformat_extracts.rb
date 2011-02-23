require "rubygems"
require "yaml"
require "pp"


tasks = []

ARGV.each do |x|
	task = []
	task.push("gunzip -v #{x}")

	item = File.basename(x, ".gz")
	task.push("gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 " +
                                "-co TILED=yes " +
                                "-co BIGTIFF=YES " +
				item + 
				" " + "102006_" + item )
	task.push("gdaladdo -r average 102006_#{item}.tif 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192")
	tasks.push(task)
end



threads = []
1.upto(6) do
        threads << Thread.new do
                loop do
                        todo = tasks.pop
                        break if (todo == nil)
                        todo.each do |i|
                                if (i.class == Array)
                                        puts("Running (A): #{i.join(" ")}")
                                        system(*i)
                                else
                                        puts("Running: #{i}")
                                        system(i)
                                end
                        end
                end
        end
end

threads.each {|t| t.join}



