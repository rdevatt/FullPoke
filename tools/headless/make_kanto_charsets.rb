# Makes overworld sprites for Kanto story Pokémon from their party icons (the
# game has no overworld Snorlax or ghost sprite): a 4x4 character sheet whose
# frames alternate the icon's two frames. The ghost is a dark, see-through
# Marowak, the way it looks before the Silph Scope reveals it.
#   FULLPOKE_RUBY_IMAGE=fullpoke-ruby tools/headless/rb.sh make_kanto_charsets.rb /game
require 'chunky_png'
game = ARGV[0] || '/game'

def sheet(icon, &tint)
  frames = [icon.crop(0, 0, 64, 64), icon.crop(64, 0, 64, 64)]
  frames.each { |f| f.pixels.map! { |c| tint.call(c) } } if tint
  out = ChunkyPNG::Image.new(256, 256, ChunkyPNG::Color::TRANSPARENT)
  4.times { |row| 4.times { |col| out.replace!(frames[col % 2], col * 64, row * 64) } }
  out
end

snorlax = ChunkyPNG::Image.from_file("#{game}/Graphics/Pokemon/Icons/SNORLAX.png")
sheet(snorlax).save("#{game}/Graphics/Characters/FP_SNORLAX.png")
marowak = ChunkyPNG::Image.from_file("#{game}/Graphics/Pokemon/Icons/MAROWAK.png")
ghost = sheet(marowak) do |c|
  a = ChunkyPNG::Color.a(c)
  next c if a == 0
  g = (ChunkyPNG::Color.r(c) + ChunkyPNG::Color.g(c) + ChunkyPNG::Color.b(c)) / 9
  ChunkyPNG::Color.rgba(g + 20, g, g + 40, a * 3 / 5)
end
ghost.save("#{game}/Graphics/Characters/FP_GHOST.png")
puts "wrote FP_SNORLAX.png and FP_GHOST.png"
