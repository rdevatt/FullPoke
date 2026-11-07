# Resolves every species/item/trainer/battleback graphic through the engine's own helpers.
GameData.load_all
miss = Hash.new { |h, k| h[k] = [] }
species = GameData::Species.keys
GameData::Species.each do |sp|
  tag = sp.form > 0 ? "#{sp.species}_#{sp.form}" : sp.species.to_s
  front = GameData::Species.front_sprite_filename(sp.species, sp.form)
  miss['front'] << tag if front.nil? || front.end_with?('000')
  back = GameData::Species.back_sprite_filename(sp.species, sp.form)
  miss['back'] << tag if back.nil? || back.end_with?('000')
  icon = GameData::Species.icon_filename(sp.species, sp.form)
  miss['icon (falls back to 000)'] << tag if icon.nil? || icon.end_with?("000")
  cry = GameData::Species.cry_filename(sp.species, sp.form)
  miss['cry'] << tag if cry.nil?
end
GameData::Item.each do |it|
  f = GameData::Item.icon_filename(it.id)
  miss['item icon (falls back to 000)'] << it.id if f.nil? || f.end_with?("/000") || f.end_with?("back")
end
GameData::TrainerType.each do |tt|
  miss['trainer sprite'] << tt.id if GameData::TrainerType.front_sprite_filename(tt.id).nil?
  miss['trainer charset'] << tt.id if !pbResolveBitmap("Graphics/Characters/trainer_#{tt.id}")
end
backs = []; GameData::MapMetadata.each { |m| backs << m.battle_background if m.battle_background }; backs.uniq!
backs.each do |b|
  %w[_bg _base0 _base1 _message].each do |suffix|
    miss['battleback'] << "#{b}#{suffix}" if !pbResolveBitmap("Graphics/Battlebacks/#{b}#{suffix}")
  end
end
total_forms = GameData::Species.count
puts "species+forms: #{total_forms}, base species: #{n = 0; GameData::Species.each_species { n += 1 }; n}, items: #{GameData::Item.count}, trainer types: #{GameData::TrainerType.count}"
miss.each do |k, v|
  ids = v.uniq
  puts "MISSING #{k}: #{ids.size}  e.g. #{ids.first(25).join(' ')}"
end
# Species without front sprites, grouped by generation for the summary
gens = Hash.new(0)
miss['front'].uniq.each { |t| s = GameData::Species.get(t.split('_')[0].to_sym) rescue nil; gens[s ? s.generation : '?'] += 1 }
puts "missing fronts by generation: #{gens.sort.to_h}"
