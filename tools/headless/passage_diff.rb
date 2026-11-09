# Lists the tiles whose passability differs between two Tilesets.rxdata files,
# as JSON { tileset id => [tile ids] } (used to seed geo/passage_fixes.json).
#   ruby passage_diff.rb <old Tilesets.rxdata> <new Tilesets.rxdata>
require_relative 'rpg_classes'
require 'json'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
a = load_rx(ARGV[0]); b = load_rx(ARGV[1])
out = {}
b.each_with_index do |t, i|
  next if !t || !a[i]
  d = (0...t.passages.xsize).select { |k| t.passages[k] != a[i].passages[k] }
  out[i.to_s] = d if !d.empty?
end
puts JSON.generate(out)
