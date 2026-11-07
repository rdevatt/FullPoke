# Points event audio at the v21 file names for sounds the map pack named differently.
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV[0]
RENAME = { 'Pokemon Healing' => 'Pkmn healing' }
n = 0
load_rx("#{dir}/MapInfos.rxdata").keys.each do |id|
  path = format('%s/Map%03d.rxdata', dir, id)
  m = load_rx(path); changed = false
  m.events.each_value { |ev| ev.pages.each { |pg| pg.list.each { |c|
    next unless [241, 245, 249, 250].include?(c.code) && c.parameters[0].is_a?(RPG::AudioFile)
    if (to = RENAME[c.parameters[0].name]) then c.parameters[0].name = to; changed = true; n += 1 end
  } } }
  File.open(path, 'wb') { |f| Marshal.dump(m, f) } if changed
end
puts "renamed #{n} audio references"
