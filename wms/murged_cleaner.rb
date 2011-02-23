require "rubygems"
require "yaml"
require "pp"


config = File.open("template.yml") {|fd| YAML.load(fd) }
blank_size = File.size?(config["murged_blank"])

ARGV.each {|x| File.unlink(x) if (File.size(x) == blank_size) }

