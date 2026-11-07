# Lists transfer commands (with any variable/switch branch guarding them) for given maps.
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV.shift
infos = load_rx("#{dir}/MapInfos.rxdata")
ARGV.map(&:to_i).each do |id|
  m = load_rx(format('%s/Map%03d.rxdata', dir, id))
  puts "== #{id} #{infos[id].name} (#{m.width}x#{m.height})"
  m.events.values.sort_by(&:id).each do |ev|
    ev.pages.each_with_index do |pg, pi|
      guard = []
      pg.list.each do |c|
        guard[c.indent] = nil
        if c.code == 111
          p = c.parameters
          guard[c.indent] = case p[0]
                            when 0 then "sw#{p[1]}#{p[2] == 0 ? '' : ' OFF'}"
                            when 1 then "var#{p[1]}#{%w[== >= <= > < !=][p[4]]}#{p[3] == 0 ? p[3 + 0 * 1] && c.parameters[3] : ''}"
                            when 12 then p[1][0, 30]
                            else "cond#{p[0]}"
                            end
          guard[c.indent] = "var#{p[1]}#{%w[== >= <= > < !=][p[4]]}#{p[3] == 0 ? p[3 + 0] : ''}" if p[0] == 1
          guard[c.indent] = "var#{p[1]}#{%w[== >= <= > < !=][p[4]]}#{p[3] == 0 ? c.parameters[3 + 0] : ''}#{p[3]} " if false
          guard[c.indent] = "var#{p[1]} #{%w[== >= <= > < !=][p[4]]} #{p[3] == 0 ? p[3] && c.parameters[3] : "var#{c.parameters[3]}"}" if p[0] == 1 && false
          guard[c.indent] = "var#{p[1]}#{%w[== >= <= > < !=][p[4]]}#{p[2] == 0 ? p[3] : "v#{p[3]}"}" if p[0] == 1
        end
        if c.code == 122
          p = c.parameters
          puts "   ev#{ev.id} (#{ev.x},#{ev.y}) p#{pi + 1}: set var#{p[0]} = #{p[3] == 0 ? p[4] : p.inspect}"
        end
        next unless c.code == 201
        p = c.parameters
        tgt = p[0] == 0 ? "#{p[1]} #{infos[p[1]]&.name} (#{p[2]},#{p[3]})" : "vars #{p[1..3].inspect}"
        g = guard.compact.join(' & ')
        puts "   ev#{ev.id} '#{ev.name}' (#{ev.x},#{ev.y}) p#{pi + 1}#{g.empty? ? '' : " [#{g}]"} -> #{tgt}"
      end
    end
  end
end
