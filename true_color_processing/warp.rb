tasks = []

ARGV.each do |x|
        next if (File.exists?(File.basename(x)))
        tasks << "gdalwarp --config GDAL_CACHEMAX 500 -wm 500 -rb -t_srs epsg:102006 -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 #{x} #{File.basename(x)} ; ~/bin/add_overviews.rb #{File.basename(x)}"
end


threads = []
1.upto(3) do
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

