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
forks
full_name
html_url
language
location
login
name
open_issues
public_gists
public_repos
pushed_at
ssh_url
type
watchers
)

$keepers = Regexp.new '^(' + keep.join('|') + ')$'
def clean hash
  hash.keys.each do |k|
    hash.delete k unless k.match $keepers
  end
end

file = ARGV.shift or fail 'Usage: clean-json.rb .../out'
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
