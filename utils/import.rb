#!/usr/bin/env ruby
require 'optparse'

options = {
  endpoint: 'api.my_app.dev:3000/v1/projects',
}

optparse = OptionParser.new do |opts|
  banner = "This tool imports GitHub projects from a file with a list.\n"
  banner << "Usage: #{File.basename(__FILE__)} [opts] <repository list file>"
  opts.banner = banner
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end

  opts.on('-e', '--endpoint URL',
          "Endpoint URL, default=\"#{options[:endpoint]}\"") do |id|
    options[:endpoint] = id
  end
end
optparse.parse!

if ARGV.size < 1
  puts "Missing repository list file!"
  puts optparse.help
  exit(-1)
end

filename = ARGV.first
fail "#{filename} does not exist" unless File.exist?(filename)

data = '--data "name=%s&rule_sets=[\"vulns\"]"'
base_cmd = "curl -v http://#{options[:endpoint]} #{data}"

# Lines should be of the form OWNER/PROJECT_NAME
# E.g. srcclr/commit-watcher
IO.readlines(filename).each do |line|
    name = line.rstrip
    cmd = base_cmd % name
    #puts cmd
    `#{cmd}`
end
