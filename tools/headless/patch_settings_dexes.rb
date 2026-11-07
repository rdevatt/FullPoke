lambda do |t|
  t.sub(/(  def self\.pokedex_names\r?\n    return \[\r?\n)      \[_INTL\("Kanto Pokédex"\), 0\],\r?\n      \[_INTL\("Johto Pokédex"\), 1\],\r?\n(      _INTL\("National Pokédex"\)\r?\n)/) do
    head, natl = $1, $2
    nl = head.include?("\r\n") ? "\r\n" : "\n"
    regions = %w[Kanto Johto Hoenn Sinnoh Unova Kalos Alola Galar]
    head + regions.each_with_index.map { |r, i| "      [_INTL(\"#{r} Pokédex\"), #{i}],#{nl}" }.join + natl
  end
end
