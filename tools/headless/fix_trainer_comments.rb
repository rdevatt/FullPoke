# The map pack's trainer events wrote "Battle \b..." instead of "Battle: \b...", so the
# v21 compiler never turned them into proper (two-page) trainer events.
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV[0]
infos = load_rx("#{dir}/MapInfos.rxdata")
fixed = []
infos.keys.sort.each do |id|
  path = format('%s/Map%03d.rxdata', dir, id)
  m = load_rx(path)
  changed = false
  m.events.each_value do |ev|
    list = ev.pages[0].list
    comments = list.select { |c| c.code == 108 }.map { |c| c.parameters[0].to_s }
    next unless comments.any? { |c| c =~ /^Type:/ } && comments.any? { |c| c =~ /^Name:/ }
    list.each do |c|
      next unless c.code == 108 && c.parameters[0] =~ /^Battle\s+(?!:)/
      c.parameters[0] = c.parameters[0].sub(/^Battle\s+/, 'Battle: ')
      changed = true
      fixed << "#{id}/#{ev.id} #{ev.name}"
    end
  end
  File.open(path, 'wb') { |f| Marshal.dump(m, f) } if changed
end
puts "fixed #{fixed.size}: #{fixed.join(', ')}"
