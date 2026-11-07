# Remaps switches the map pack used under a different numbering to the ones
# Essentials v21.1 actually uses, matching on event structure (not just the number).
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV[0]
infos = load_rx("#{dir}/MapInfos.rxdata")
stats = Hash.new(0)
infos.keys.sort.each do |id|
  path = format('%s/Map%03d.rxdata', dir, id)
  m = load_rx(path)
  changed = false
  m.events.each_value do |ev|
    ev.pages.each do |pg|
      c = pg.condition
      list = pg.list
      # Door exit page: autorun, conditioned on switch 12, starts with an onEvent? branch
      # and ends by turning on temp switch A. Its switch should be 's:tsOff?("A")' (22).
      if c.switch1_valid && c.switch1_id == 12 && pg.trigger == 3 &&
         list[0].code == 111 && list[0].parameters[0] == 12 && list[0].parameters[1].to_s.include?('onEvent?') &&
         list.any? { |cmd| cmd.code == 355 && cmd.parameters[0].to_s.include?('setTempSwitchOn("A")') }
        c.switch1_id = 22; changed = true; stats['door exit page 12->22'] += 1
      end
      # Poké Center nurse: the "heal after blacking out" autorun page uses switch 5
      # where v21 uses switch 1 ("Starting over"); its Pokérus note uses 3 where v21 uses 2.
      is_nurse = list.any? { |cmd| cmd.code == 314 } && list.any? { |cmd| cmd.code == 355 && cmd.parameters[0].to_s.include?('$game_variables[43]') }
      next unless is_nurse
      if c.switch1_valid && c.switch1_id == 5 && pg.trigger == 3
        c.switch1_id = 1; changed = true; stats['nurse autorun 5->1'] += 1
      end
      list.each do |cmd|
        next unless cmd.code == 121
        p = cmd.parameters
        if p[0] == 5 && p[1] == 5 then p[0] = p[1] = 1; changed = true; stats['nurse switch op 5->1'] += 1
        elsif p[0] == 3 && p[1] == 3 && p[2] == 0 then p[0] = p[1] = 2; changed = true; stats['nurse pokerus 3->2'] += 1
        end
      end
    end
  end
  File.open(path, 'wb') { |f| Marshal.dump(m, f) } if changed
end
stats.each { |k, v| puts "#{k}: #{v}" }
