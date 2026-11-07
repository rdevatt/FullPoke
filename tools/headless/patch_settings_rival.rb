lambda do |t|
  t.sub(/(    \[:CHAMPION, 12\])(\r?\n)(  \])/) do
    nl = $2
    "#{$1},#{nl}    # FullPoke: the intro stores the Kanto rival's name in Variable 27.#{nl}" \
    "    [:KANTORIVAL1, 27],#{nl}    [:KANTORIVAL2, 27]#{nl}#{$3}"
  end
end
