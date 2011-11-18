ARGV.each do |x|
	bin = File.basename(x).split(/[NSEW]/)[1] + File.basename(x).split(/\d+/)[1]
	
	puts bin

	system("mkdir", bin) if (!File.exists?(bin))
	system("ln", "-v", x, bin + "/" + File.basename(x))
end
