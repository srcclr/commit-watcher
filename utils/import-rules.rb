#!/usr/bin/env ruby

=begin
Copyright 2016 SourceClear Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require 'optparse'
require 'json'

options = {
  endpoint: 'api.my_app.dev:3000/v1/rules',
}

optparse = OptionParser.new do |opts|
  banner = "Imports rules stored in JSON format.\n"
  banner << "Usage: #{File.basename(__FILE__)} [opts] <json rules file>"
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
  puts "Missing json rules file!"
  puts optparse.help
  exit(-1)
end

filename = ARGV.first
fail "#{filename} does not exist" unless File.exist?(filename)

data = '--data "name=\"%s\"&rule_type_id=%s&value=\"%s\"&description=\"%s\""'
base_cmd = "curl -v http://#{options[:endpoint]} #{data}"

rules = IO.read(filename)
#fail "Empty rules file" if rules.empty?

json = JSON.parse(rules.rstrip, symbolize_names: true)
json.each do |rule|
  puts rule
  cmd = base_cmd % [rule[:name], rule[:rule_type_id], rule[:value], rule[:description]]
  #puts cmd
  `#{cmd}`
end
