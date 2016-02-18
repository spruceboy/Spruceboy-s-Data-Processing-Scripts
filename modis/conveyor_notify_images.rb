#/usr/bin/env ruby
# very simple util to mail me (jay@alaska.edu) after images have been generated.


require "mail"
require "fileutils"



items = { "Night" => "*_23.alaska_albers.small.png",
	"Land" => "*_7_2_1_500m_1.alaska_albers.small.png",
	"2_6_1" => "*_2_6_1_500m_1.alaska_albers.small.png",
	"NC" => "*_ATM1_500_ATM4_ATM3_ATM1.alaska_albers.small.png",
	"3_6_7" => "*_3_6_7.alaska_albers.small.png"
   }

FileUtils.cd (ARGV.first) do 

	files = []
	bod = ["For #{File.basename(ARGV.first)}, the following images were generated:"]


	items.keys.each do |k|
		s = Dir.glob(items[k]) 
		if ( s.length == 1)
			bod << "#{k}:ok"
			files << s.first
		else
			bod << "#{k}:missing"
		end
	end


	mail = Mail.new do
  		from     'jay@alaska.edu'
  		to       'jay@alaska.edu'
  		subject  "IM:#{File.basename(ARGV.first)}"
		body 	bod.join("\n")
	end
	files.each {|x| mail.add_file(x) }

	mail.delivery_method :sendmail
	puts("Sending notification..")
	mail.deliver
	puts("Done.")

end
