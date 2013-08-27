#!/usr/bin/env ruby

require 'json'

keep = %w(
bio
blog
company
description
email
followers
following
full_name
location
login
name
public_gists
public_repos
pushed_at
type
)

$keepers = Regexp.new '^(' + keep.join('|') + ')$'
def clean hash
  hash.keys.each do |k|
    hash.delete k unless k.match $keepers
  end
end

file = ARGV.shift or fail 'Usage: clean-json.rb .../api-out'
`cp #{file} /tmp/` or fail
data = JSON.load File.read(file)
if data.kind_of? Array
  data.each do |o|
    clean o
  end
else
  clean data
end

File.open(file, 'w').puts JSON.pretty_generate data
