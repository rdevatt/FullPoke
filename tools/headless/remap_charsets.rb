# Points events whose charset file doesn't exist at an existing graphic for the same role.
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV[0]
MAP = {
  'trchar060' => 'NPC 16',                       # Poké Center nurse
  'fk053-shopkeeper' => 'NPC 19',                # Poké Mart clerk
  'trchar055' => 'NPC 19', 'fk049' => 'NPC 19',  # Route 1 Mart employee handing out Potions
  'fk048-prof-oak' => 'trainer_PROFESSOR',
  'fk060-brock' => 'trainer_KANTOLEADER_Brock',
  'fk061-misty' => 'trainer_KANTOLEADER_Misty',
  'Avatar-Gary1' => 'trainer_KANTORIVAL1',
  'fk012-bug-catcher' => 'trainer_KANTOBUGCATCHER',
  'fk007-youngster' => 'trainer_KANTOYOUNGSTER',
  'fk023' => 'NPC 22', 'fk001' => 'NPC 27', 'fk008' => 'NPC 06', 'fk013' => 'NPC 13',
  'fk010' => 'NPC 10', 'fk016' => 'NPC 07', 'fk017' => 'NPC 15', 'fk019' => 'NPC 17',
  'fk051' => 'NPC 11', 'Character10 n°3' => 'NPC 04',
  'pokeballs on left' => 'Healing balls 1', 'pokeballs on right' => 'Healing balls 2'
}
infos = load_rx("#{dir}/MapInfos.rxdata")
count = Hash.new(0)
infos.keys.sort.each do |id|
  path = format('%s/Map%03d.rxdata', dir, id)
  m = load_rx(path)
  changed = false
  swap = lambda do |name|
    key = name.to_s.dup.force_encoding('UTF-8')
    if MAP[key] then count[key] += 1; changed = true; MAP[key] else name end
  end
  m.events.each_value do |ev|
    ev.pages.each do |pg|
      pg.graphic.character_name = swap.call(pg.graphic.character_name)
      routes = [pg.move_route] + pg.list.select { |c| c.code == 209 }.map { |c| c.parameters[1] }
      routes.each { |r| r.list.each { |mc| mc.parameters[0] = swap.call(mc.parameters[0]) if mc.code == 41 } }
      pg.list.each { |c| c.parameters[0] = swap.call(c.parameters[0]) if c.code == 509 && false }
    end
  end
  File.open(path, 'wb') { |f| Marshal.dump(m, f) } if changed
end
count.each { |k, v| puts "#{k} -> #{MAP[k]}: #{v}" }
