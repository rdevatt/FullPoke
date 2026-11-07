# Converts the project's v18-format PBS files into Pokémon Essentials v21.1 format.
#   ruby convert_pbs.rb <repo_pbs_dir> <v21_base_pbs_dir> <out_dir>
repo, base, out = ARGV
SEP = "#-------------------------------"
HEADER = "# See the documentation on the wiki to learn how to edit this file.\n"
def read_lines(path) = File.read(path, encoding: 'bom|utf-8').gsub("\r", '').split("\n")
def uncomment(l) = l.sub(/\s*#.*$/, '').strip

#---------------------------------------------------------------- encounters
V18_CHANCES = {
  'Land' => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1], 'Cave' => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1],
  'Water' => [60, 30, 5, 4, 1], 'RockSmash' => [60, 30, 5, 4, 1], 'OldRod' => [70, 30], 'GoodRod' => [60, 20, 20],
  'SuperRod' => [40, 40, 15, 4, 1], 'HeadbuttLow' => [30, 25, 20, 10, 5, 5, 4, 1], 'HeadbuttHigh' => [30, 25, 20, 10, 5, 5, 4, 1],
  'LandMorning' => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1], 'LandDay' => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1],
  'LandNight' => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1], 'BugContest' => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
}
# Which v18 density (land, cave, water) each type used, and the v21 step chance that
# corresponds to v18's default density for it (v21's own defaults: Land 21, Cave 5, Water 2).
DENSITY_SLOT = { 'Land' => 0, 'LandMorning' => 0, 'LandDay' => 0, 'LandNight' => 0, 'BugContest' => 0, 'Cave' => 1, 'Water' => 2 }
V18_DEFAULT = [25, 10, 10]
V21_DEFAULT = [21, 5, 2]
maps = []
cur = nil; enc_type = nil
read_lines("#{repo}/encounters.txt").each do |raw|
  line = raw.strip
  next if line.empty? || line.start_with?('#')
  if line =~ /^(\d+)\s*(#\s*(.*))?$/ && !line.include?(',')
    cur = { id: $1.to_i, name: $3.to_s.strip, densities: V18_DEFAULT.dup, types: {} }
    maps << cur; enc_type = nil
  elsif line =~ /^\d+\s*,\s*\d+\s*,\s*\d+$/ && enc_type.nil?
    cur[:densities] = line.split(',').map(&:to_i)
  elsif V18_CHANCES.key?(line)
    enc_type = line; cur[:types][enc_type] = []
  else
    sp, lo, hi = uncomment(line).split(',').map(&:strip)
    cur[:types][enc_type] << [sp, lo.to_i, (hi || lo).to_i]
  end
end
File.open("#{out}/encounters.txt", 'w') do |f|
  f.write(HEADER)
  maps.each do |m|
    f.puts SEP
    f.puts format('[%03d]%s', m[:id], m[:name].empty? ? '' : " # #{m[:name]}")
    m[:types].each do |type, slots|
      chances = V18_CHANCES[type]
      if slots.size != chances.size
        warn "encounters: map #{m[:id]} #{type} has #{slots.size} slots, expected #{chances.size}"
      end
      merged = Hash.new(0)
      slots.each_with_index { |s, i| merged[s] += chances[i] || 0 }
      slot = DENSITY_SLOT[type]
      if slot
        step = (m[:densities][slot] * V21_DEFAULT[slot].to_f / V18_DEFAULT[slot]).round
        f.puts "#{type},#{[step, 1].max}"
      else
        f.puts type
      end
      merged.sort_by { |s, c| [-c, s[0]] }.each do |(sp, lo, hi), c|
        f.puts lo == hi ? "    #{c},#{sp},#{lo}" : "    #{c},#{sp},#{lo},#{hi}"
      end
    end
  end
end

#---------------------------------------------------------------- trainer types
# BGM names the v18 types referenced; only tracks that exist in Audio/ are kept,
# the rest fall back to these stock v21 tracks.
BGM_FALLBACK = {
  'REG0_10_TrainerBattle' => 'Battle trainer', 'REG0_14_GymBattle' => 'Battle Gym Leader',
  'REG0_11_VictoryTrainer' => 'Battle victory trainer', 'REG0_15_GymVictory' => 'Battle victory leader',
  'REG0_08_MaleTrainAppear' => nil
}
audio = Dir.glob("#{repo}/../Audio/{BGM,ME}/*").map { |p| File.basename(p, '.*').downcase }
fix_bgm = lambda do |n|
  n = n.to_s.strip
  next nil if n.empty?
  next n if audio.include?(n.downcase)
  BGM_FALLBACK.fetch(n) { warn "trainer types: unknown BGM #{n}"; nil }
end
custom_types = []
read_lines("#{repo}/trainertypes.txt").each do |raw|
  line = uncomment(raw)
  next if line.empty?
  f = line.split(',', -1).map(&:strip)
  custom_types << { id: f[1], name: f[2], money: f[3], bgm: fix_bgm.call(f[4]), victory: fix_bgm.call(f[5]),
                    intro: fix_bgm.call(f[6]), gender: f[7], skill: f[8] }
end
base_tt = File.read("#{base}/trainer_types.txt", encoding: 'bom|utf-8').gsub("\r", '')
base_ids = base_tt.scan(/^\[(\w+)\]/).flatten
File.open("#{out}/trainer_types.txt", 'w') do |f|
  f.write(base_tt.sub(/\n*\z/, "\n"))
  f.puts SEP
  f.puts "# FullPoke custom trainer types (converted from the v18 trainertypes.txt)"
  custom_types.each do |t|
    if base_ids.include?(t[:id]) then warn "trainer type #{t[:id]} already exists; skipped"; next end
    f.puts SEP
    f.puts "[#{t[:id]}]"
    f.puts "Name = #{t[:name]}"
    f.puts "Gender = #{t[:gender].empty? ? 'Unknown' : t[:gender]}"
    f.puts "BaseMoney = #{t[:money]}"
    f.puts "SkillLevel = #{t[:skill]}" unless t[:skill].to_s.empty?
    f.puts "IntroBGM = #{t[:intro]}" if t[:intro]
    f.puts "BattleBGM = #{t[:bgm]}" if t[:bgm]
    f.puts "VictoryBGM = #{t[:victory]}" if t[:victory]
  end
end

#---------------------------------------------------------------- trainers
BALLS = %i[POKEBALL GREATBALL SAFARIBALL ULTRABALL MASTERBALL NETBALL DIVEBALL NESTBALL REPEATBALL TIMERBALL
           LUXURYBALL PREMIERBALL DUSKBALL HEALBALL QUICKBALL CHERISHBALL FASTBALL LEVELBALL LUREBALL HEAVYBALL
           LOVEBALL FRIENDBALL MOONBALL SPORTBALL DREAMBALL BEASTBALL]
trainers = []
state = 0; t = nil; remaining = 0; comment = nil
read_lines("#{repo}/trainers.txt").each do |raw|
  if raw.strip.start_with?('#')
    c = raw.strip.sub(/^#+/, '').strip
    comment = c unless c.empty? || c.start_with?('-') || c.start_with?('See the documentation')
    next
  end
  line = uncomment(raw)
  next if line.empty?
  case state
  when 0 then t = { type: line, comment: comment, items: [], pokemon: [] }; trainers << t; state = 1
  when 1
    name, ver = line.split(',').map(&:strip); t[:name] = name; t[:version] = ver.to_i; state = 2
  when 2
    f = line.split(',').map(&:strip); remaining = f.shift.to_i; t[:items] = f.reject(&:empty?); state = 3
  when 3
    f = line.split(',', -1).map(&:strip)
    pk = { species: f[0], level: f[1] }
    pk[:item] = f[2] unless f[2].to_s.empty?
    moves = (f[3..6] || []).reject { |m| m.nil? || m.empty? }
    pk[:moves] = moves unless moves.empty?
    pk[:ability_index] = f[7] unless f[7].to_s.empty?
    pk[:gender] = { 'M' => 'male', 'F' => 'female' }[f[8].to_s.upcase] unless f[8].to_s.empty?
    pk[:form] = f[9] unless f[9].to_s.empty?
    pk[:shiny] = !f[10].to_s.empty? && f[10].to_s !~ /^(false|0)$/i
    pk[:nature] = f[11] unless f[11].to_s.empty?
    pk[:iv] = f[12] unless f[12].to_s.empty?
    pk[:happiness] = f[13] unless f[13].to_s.empty?
    pk[:name] = f[14] unless f[14].to_s.empty?
    pk[:shadow] = !f[15].to_s.empty? && f[15].to_s !~ /^(false|0)$/i
    pk[:ball] = BALLS[f[16].to_i] unless f[16].to_s.empty?
    t[:pokemon] << pk
    remaining -= 1
    state = 0 if remaining <= 0
    comment = nil if state == 0
  end
end
File.open("#{out}/trainers.txt", 'w') do |f|
  f.write(HEADER)
  last_comment = nil
  trainers.each do |tr|
    f.puts SEP
    if tr[:comment] && tr[:comment] != last_comment
      f.puts "# #{tr[:comment]}"; last_comment = tr[:comment]
    end
    f.puts tr[:version] > 0 ? "[#{tr[:type]},#{tr[:name]},#{tr[:version]}]" : "[#{tr[:type]},#{tr[:name]}]"
    f.puts "Items = #{tr[:items].join(',')}" unless tr[:items].empty?
    tr[:pokemon].each do |pk|
      f.puts "Pokemon = #{pk[:species]},#{pk[:level]}"
      f.puts "    Name = #{pk[:name]}" if pk[:name]
      f.puts "    Form = #{pk[:form]}" if pk[:form]
      f.puts "    Moves = #{pk[:moves].join(',')}" if pk[:moves]
      f.puts "    AbilityIndex = #{pk[:ability_index]}" if pk[:ability_index]
      f.puts "    Item = #{pk[:item]}" if pk[:item]
      f.puts "    Gender = #{pk[:gender]}" if pk[:gender]
      f.puts "    Nature = #{pk[:nature]}" if pk[:nature]
      f.puts "    IV = #{([pk[:iv]] * 6).join(',')}" if pk[:iv]
      f.puts "    Happiness = #{pk[:happiness]}" if pk[:happiness]
      f.puts "    Shiny = true" if pk[:shiny]
      f.puts "    Shadow = true" if pk[:shadow]
      f.puts "    Ball = #{pk[:ball]}" if pk[:ball]
    end
  end
end
puts "encounter maps: #{maps.size}, custom trainer types: #{custom_types.size}, trainers: #{trainers.size}"
