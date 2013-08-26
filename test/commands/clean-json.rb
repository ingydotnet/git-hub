#!/usr/bin/env ruby

require 'json'

keep = %w(
bio
blog
company
email
followers
following
location
login
name
public_gists
public_repos
type
)

file = ARGV.shift or fail 'Usage: clean-json.rb file.json'
data = JSON.load File.open(file).read

keepers = Regexp.new '^(' + keep.join('|') + ')$'
data.keys.each do |k|
  data.delete k unless k.match keepers
end

File.open(file, 'w').puts JSON.pretty_generate data
