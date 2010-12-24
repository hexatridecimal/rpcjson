#!/opt/ruby-enterprise/bin/ruby

require 'rubygems'
require './lib/rpcjson.rb'

bc = RPC::JSON::Client.new 'http://Fr0bNab1t:232js8ajdkAJdsjdiKDSieksk4@127.0.0.1:8332', 1.1

begin
  puts bc.getaccount ARGV.pop
rescue RPC::JSON::Client::Error => e
  puts "Got an error: #{e}: #{e.error.to_json}"
end
