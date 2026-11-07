# Rewrites Essentials v18 script idioms in map/common events to v21.1 equivalents.
# The v21 compiler (run afterwards) handles Kernel./$Trainer/$PokemonBag and turns
# pbTrainerBattle branches into TrainerBattle.start; this handles what it doesn't.
#   ruby convert_events.rb <Data dir> <lose_texts_out.tsv>
require_relative 'rpg_classes'
require 'set'
dir, lose_out = ARGV
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
def save_rx(o, p) = File.open(p, 'wb') { |f| Marshal.dump(o, f) }

TRAINER_TYPE_RENAMES = { 'RIVAL' => 'KANTORIVAL1', 'LEADER_Brock' => 'KANTOLEADER_Brock' }
ITEM_RENAMES = { 'POKeBALL' => 'POKEBALL' }
$lose_texts = {}

def convert(script)
  s = script.dup
  s.gsub!(/(?:::)?PBItems::(\w+)/) { ":#{ITEM_RENAMES.fetch($1, $1)}" }
  s.gsub!(/(?:::)?PBSpecies::(\w+)/) { ":#{$1}" }
  s.gsub!(/(?:::)?PBMoves::(\w+)/) { ":#{$1}" }
  s.gsub!(/(?:::)?PBTrainers::(\w+)/) { ":#{TRAINER_TYPE_RENAMES.fetch($1, $1)}" }
  s.gsub!(/\$Trainer\.badges\[(\d+)\]\s*=\s*true/) { "$player.badges[#{$1}] = true" }
  # Record each trainer's defeat line so it can become LoseText in trainers.txt.
  if s =~ /pbTrainerBattle\(\s*:(\w+)\s*,\s*"([^"]*)"\s*,\s*_I\(\s*"((?:[^"\\]|\\.)*)"\s*\)(?:\s*,\s*\w+\s*,\s*(\d+))?/
    key = [$1, $2, $4.to_i]
    $lose_texts[key] ||= $3
  end
  s
end

changed_maps = []
infos = load_rx("#{dir}/MapInfos.rxdata")
infos.keys.sort.each do |id|
  path = format('%s/Map%03d.rxdata', dir, id)
  map = load_rx(path)
  changed = false
  map.events.each_value do |ev|
    ev.pages.each do |pg|
      pg.list.each do |cmd|
        idx = case cmd.code
              when 355, 655 then 0
              when 111 then (cmd.parameters[0] == 12 ? 1 : nil)
              end
        next unless idx && cmd.parameters[idx].is_a?(String)
        new_s = convert(cmd.parameters[idx])
        next if new_s == cmd.parameters[idx]
        cmd.parameters[idx] = new_s
        changed = true
      end
    end
  end
  if changed
    save_rx(map, path)
    changed_maps << id
  end
end
File.open(lose_out, 'w') { |f| $lose_texts.each { |(t, n, v), txt| f.puts [t, n, v, txt].join("\t") } }
puts "converted maps: #{changed_maps.join(', ')}"
