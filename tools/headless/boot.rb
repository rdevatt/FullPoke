# Boots Pokémon Essentials headlessly: loads the game's Scripts.rxdata (all sections
# except Main) on top of the RGSS stubs, then runs plugins. Usage:
#   GAME_DIR=/game ruby boot.rb <task.rb> [args...]
require 'zlib'
require_relative 'rgss_stubs'
game_dir = ENV['GAME_DIR'] || '/game'
Dir.chdir(game_dir)
$DEBUG = ENV['HEADLESS_DEBUG'] != '0'
scripts = load_data('Data/Scripts.rxdata')
$RGSS_SCRIPTS = scripts
scripts.each_with_index do |(_id, name, code), i|
  next if name == 'Main'
  text = Zlib::Inflate.inflate(code)
  text.force_encoding(Encoding::UTF_8)
  begin
    eval(text, TOPLEVEL_BINDING, "[#{i}] #{name}")
  rescue Exception => e
    $stderr.puts "Error loading script section #{i} (#{name}): #{e.class}: #{e.message}"
    $stderr.puts e.backtrace.first(8).join("\n")
    exit 1
  end
end
def pbPrintException(e)
  $stderr.puts "EXCEPTION: #{e.class}: #{e.message}"
  $stderr.puts e.backtrace.first(25).join("\n") if e.backtrace
end
def print(*a); $stdout.puts(*a); end
def p(*a); a.each { |x| $stdout.puts x.inspect }; a.length <= 1 ? a[0] : a; end
task = ARGV.shift
load File.expand_path(task, __dir__) if task
