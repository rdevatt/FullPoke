class Battle
  alias_method :_hl_pbStartBattle, :pbStartBattle
  def pbStartBattle
    log "TRACE pbStartBattle scene=#{@scene.class} controlPlayer=#{@controlPlayer} party=#{@party1.map { |p| "#{p.species}#{p.hp}/#{p.totalhp}" }} foes=#{@party2.map { |p| "#{p.species}#{p.hp}" }}"
    r = _hl_pbStartBattle
    log "TRACE decision=#{r}"
    r
  rescue Exception => e
    log "TRACE EXCEPTION #{e.class}: #{e.message} #{e.backtrace.first(6).join(' | ')}"
    raise
  end
end
