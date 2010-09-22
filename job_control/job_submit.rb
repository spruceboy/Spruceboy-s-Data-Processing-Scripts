Dir.glob("*.job") {|x| system("qsub #{x}") }
