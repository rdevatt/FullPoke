# Compiles all PBS files (and runs the event compiler) exactly as the game does in debug mode.
PluginManager.runPlugins
begin
  Compiler.compile_all(true)
  puts "COMPILE OK"
rescue Exception => e
  puts "COMPILE FAILED: #{e.class}: #{e.message}"
  puts e.backtrace.first(12).join("\n")
  exit 1
end
