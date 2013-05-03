#!/usr/bin/env ruby
require "trollop"
#############
# Simple command to run several things at once
# ./do_several_at_once.rb -h is your friend/fiend


#wrapper for system - runs command on task
def runner ( command,task, opts)
  puts("Info: Running: #{command} #{task}") if (opts[:verbrose])
  start_time = Time.now
  system(command + " " + task)
  puts("Info: Done in #{(Time.now - start_time)/60.0}m.") if (opts[:verbrose])
end


## Command line parsing action..
parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
  This util runs a command on a list of files, running several at a time.  

Usage:
      do_several_at_once.rb [options] --command_to_run <command> <file1> <file2> ....
where [options] is:
EOS

  opt :threads, "The number to run at once, defaults to 2", :default =>  2 
  opt :command_to_run, "This is the command to run (required!).", :type => String
  opt :verbrose, "Maxium Verbrosity.", :short => "V"
  opt :dry_run, "Don't actually run the command(s)"
end

opts = Trollop::with_standard_exception_handling(parser) do
  o = parser.parse ARGV
  raise Trollop::HelpNeeded if ARGV.length == 0 # show help screen
  #command is required..
  if(!o[:command_to_run] )
    puts("Error: A command to run is required - use the \"--command_to_run\" flag.\n\n\n")
    raise Trollop::HelpNeeded
  end
  #check for strange threads values
  if(o[:threads]<=0 )
    puts("Error: Number of threads must be greater than 0\n\n\n\n\n\n")
   raise Trollop::HelpNeeded
  end
  o
end


list = []
ARGV.each do |z|
	list += File.readlines(z)
end


list.sort!

#Now, do actual work..
threads = []
1.upto(opts[:threads].to_i) do
        threads << Thread.new do
                loop do
                        todo = list.pop
                        break if (todo == nil)
			todo.chomp!
                        puts("Info: Running #{opts[:command_to_run]} #{todo}")
                        runner(opts[:command_to_run], todo, opts) if (!opts[:dry_run])
                end
        end
end

threads.each {|t| t.join}
