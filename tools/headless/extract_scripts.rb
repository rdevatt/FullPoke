require 'zlib'
src, out = ARGV
scripts = File.open(src, 'rb') { |f| Marshal.load(f) }
File.open(File.join(out, '_index.txt'), 'w') do |idx|
  scripts.each_with_index do |(id, name, code), i|
    text = Zlib::Inflate.inflate(code)
    fn = format('%04d_%s.rb', i, name.to_s.gsub(/[^\w\-. ]/, '_')[0, 60])
    File.binwrite(File.join(out, fn), text)
    idx.puts "#{i}\t#{id}\t#{name}\t#{text.bytesize}"
  end
end
puts scripts.size
