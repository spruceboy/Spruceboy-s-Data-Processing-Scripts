ARGV.each do |x|
 bits = x.split("_")
 days = bits[2].split("-")
 name = sprintf("MODIS_%s_%03d-%03d.png", bits[1], days[0].to_i, days[1].to_i)
 system("cp -v #{x} #{name}")
end
