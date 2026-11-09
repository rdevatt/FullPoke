# Adds the Paldea Pokédex (regional dex 8) to Settings.pokedex_names, after Galar.
#   ruby patch_scripts.rb /game/Data/Scripts.rxdata Settings patch_settings_paldea_dex.rb
lambda do |t|
  t.sub(/(      \[_INTL\("Galar Pokédex"\), 7\],(\r?\n))/) { "#{$1}      [_INTL(\"Paldea Pokédex\"), 8],#{$2}" }
end
