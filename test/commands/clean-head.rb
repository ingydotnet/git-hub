#!/usr/bin/env ruby

keep = %w(
HTTP
Server:
Content-Type:
Status:
Content-Length:
)

file = ARGV.shift or fail 'Usage: clean-head.rb .../api-head'
`cp #{file} /tmp/` or fail 123

keepers = Regexp.new '^(' + keep.join('|') + ')'
lines = File.readlines(file)
out = File.open(file, 'w')
lines.each do |l|
  out.print l if l.match keepers
end
