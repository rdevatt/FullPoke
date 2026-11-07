# Edits a section of Scripts.rxdata in place.
#   ruby patch_scripts.rb <Scripts.rxdata> <section name> <file with Ruby: lambda taking and returning the text>
require 'zlib'
path, section, patch_file = ARGV
scripts = File.open(path, 'rb') { |f| Marshal.load(f) }
entry = scripts.find { |s| s[1] == section } or abort "no section #{section}"
text = Zlib::Inflate.inflate(entry[2]).force_encoding('UTF-8')
new_text = eval(File.read(patch_file)).call(text.dup)
abort "patch made no change" if new_text == text
entry[2] = Zlib::Deflate.deflate(new_text)
File.open(path, 'wb') { |f| Marshal.dump(scripts, f) }
puts "patched #{section}"
