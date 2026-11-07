# Lists every switch / variable an event reads or writes, with its System name.
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV[0]
sys = load_rx("#{dir}/System.rxdata")
infos = load_rx("#{dir}/MapInfos.rxdata")
sw = Hash.new { |h, k| h[k] = [] }; var = Hash.new { |h, k| h[k] = [] }
infos.keys.sort.each do |id|
  m = load_rx(format('%s/Map%03d.rxdata', dir, id))
  m.events.each_value do |ev|
    ev.pages.each_with_index do |pg, pi|
      w = "#{id}/#{ev.id}"
      c = pg.condition
      sw[c.switch1_id] << "#{w} cond" if c.switch1_valid
      sw[c.switch2_id] << "#{w} cond" if c.switch2_valid
      var[c.variable_id] << "#{w} cond" if c.variable_valid
      pg.list.each do |cmd|
        p = cmd.parameters
        case cmd.code
        when 121 then (p[0]..p[1]).each { |s| sw[s] << "#{w} set#{p[2] == 0 ? 'ON' : 'OFF'}" }
        when 122 then (p[0]..p[1]).each { |v| var[v] << "#{w} set" }
        when 111
          sw[p[1]] << "#{w} if" if p[0] == 0
          var[p[1]] << "#{w} if" if p[0] == 1
        when 101, 401 then p[0].to_s.scan(/\\v\[(\d+)\]/i) { var[$1.to_i] << "#{w} text" }
        when 355, 655 then p[0].to_s.scan(/(?:\$game_switches\[|pbSet\(|pbGet\(|\$game_variables\[)(\d+)/) { (p[0].include?('switch') ? sw : var)[$1.to_i] << "#{w} script" }
        end
      end
    end
  end
end
puts "SWITCHES"; sw.keys.sort.each { |k| puts "  #{k} '#{sys.switches[k]}': #{sw[k].uniq.size} uses e.g. #{sw[k].uniq.first(4).join(', ')}" }
puts "VARIABLES"; var.keys.sort.each { |k| puts "  #{k} '#{sys.variables[k]}': #{var[k].uniq.size} uses e.g. #{var[k].uniq.first(4).join(', ')}" }
