# Headless stand-ins for the RGSS/mkxp-z built-ins that Pokémon Essentials v21.1
# expects. Display and audio calls are no-ops; Bitmap tracks dimensions (read from
# PNG headers) and raises when an image file is missing so missing graphics surface.
require 'zlib'
$HEADLESS = true
$MISSING_FILES = Hash.new(0)

module RPG; end
require_relative 'rpg_classes'

# Windows paths are case-insensitive (Essentials relies on this, e.g. "Data/map001.rxdata"),
# so resolve each path component against what's actually on disk.
def ci_path(fn)
  return fn if File.exist?(fn)
  parts = fn.split('/')
  cur = parts.first.empty? ? '/' : '.'
  parts.each_with_index do |part, i|
    next if part.empty? || (i == 0 && part == '.')
    cand = File.join(cur, part)
    unless File.exist?(cand)
      match = File.directory?(cur) && Dir.children(cur).find { |c| c.casecmp?(part) }
      return fn unless match
      cand = File.join(cur, match)
    end
    cur = cand
  end
  cur.sub(%r{^\./}, '')
end
def load_data(fn)
  File.open(ci_path(fn), 'rb') { |f| Marshal.load(f) }
end
def save_data(obj, fn)
  File.open(ci_path(fn), 'wb') { |f| Marshal.dump(obj, f) }
end

class Hangup < Exception; end
class Reset < Exception; end

class Rect
  attr_accessor :x, :y, :width, :height
  def initialize(x = 0, y = 0, w = 0, h = 0); @x, @y, @width, @height = x, y, w, h; end
  def set(x, y = 0, w = 0, h = 0)
    if x.is_a?(Rect) then @x, @y, @width, @height = x.x, x.y, x.width, x.height
    else @x, @y, @width, @height = x, y, w, h end
    self
  end
  def empty; @x = @y = @width = @height = 0; self; end
  def ==(o); o.is_a?(Rect) && [x, y, width, height] == [o.x, o.y, o.width, o.height]; end
end

class Color
  def set(r, g = 0, b = 0, a = 255)
    if r.is_a?(Color) then @red, @green, @blue, @alpha = r.red, r.green, r.blue, r.alpha
    else @red, @green, @blue, @alpha = r, g, b, a end
    self
  end
  def ==(o); o.is_a?(Color) && [red, green, blue, alpha] == [o.red, o.green, o.blue, o.alpha]; end
end
class Tone
  def set(r, g = 0, b = 0, gr = 0)
    if r.is_a?(Tone) then @red, @green, @blue, @gray = r.red, r.green, r.blue, r.gray
    else @red, @green, @blue, @gray = r, g, b, gr end
    self
  end
  def ==(o); o.is_a?(Tone) && [red, green, blue, gray] == [o.red, o.green, o.blue, o.gray]; end
end

class Font
  class << self
    attr_accessor :default_name, :default_size, :default_bold, :default_italic, :default_color,
                  :default_outline, :default_shadow, :default_out_color, :default_solid_fill
    def exist?(_n); true; end
  end
  self.default_name = ['Arial']; self.default_size = 22
  attr_accessor :name, :size, :bold, :italic, :color, :outline, :shadow, :out_color
  def initialize(name = nil, size = nil); @name = name || Font.default_name; @size = size || 22; @color = Color.new(255, 255, 255); @bold = false; @italic = false; end
end

module HeadlessImage
  module_function
  def resolve(path)
    return path if File.file?(path)
    %w[.png .gif .jpg .jpeg .bmp].each { |ext| return path + ext if File.file?(path + ext) }
    # case-insensitive fallback (Windows file system semantics)
    dir = File.dirname(path); base = File.basename(path).downcase
    if File.directory?(dir)
      Dir.children(dir).each do |c|
        cb = c.downcase
        return File.join(dir, c) if cb == base || %w[.png .gif .jpg .jpeg .bmp].any? { |e| cb == base + e }
      end
    end
    nil
  end
  def dimensions(file)
    data = File.binread(file, 32) rescue (return [32, 32])
    if data[0, 8] == "\x89PNG\r\n\x1A\n".b then data[16, 8].unpack('NN')
    elsif data[0, 3] == 'GIF' then data[6, 4].unpack('vv')
    elsif data[0, 2] == 'BM' then d = data[18, 8].unpack('l<l<'); [d[0], d[1].abs]
    else [32, 32] end
  end
end

class Bitmap
  attr_reader :width, :height
  attr_accessor :font, :path
  def initialize(*args)
    @font = Font.new
    if args[0].is_a?(String)
      file = HeadlessImage.resolve(args[0])
      unless file
        $MISSING_FILES[args[0]] += 1
        raise Errno::ENOENT, "File #{args[0]} not found."
      end
      @path = file
      @width, @height = HeadlessImage.dimensions(file)
    else
      @width, @height = (args[0] || 32).to_i, (args[1] || 32).to_i
    end
    @disposed = false
  end
  def rect; Rect.new(0, 0, @width, @height); end
  def dispose; @disposed = true; end
  def disposed?; @disposed; end
  def clone; b = super; b.instance_variable_set(:@font, @font.dup); b; end
  def text_size(str); Rect.new(0, 0, str.to_s.length * 10, 22); end
  def get_pixel(_x, _y); Color.new(0, 0, 0, 0); end
  def draw_text(*_a); end
  def blt(*_a); end
  def stretch_blt(*_a); end
  def fill_rect(*_a); end
  def gradient_fill_rect(*_a); end
  def clear(*_a); end
  def clear_rect(*_a); end
  def set_pixel(*_a); end
  def hue_change(*_a); end
  def blur(*_a); end
  def radial_blur(*_a); end
  def raw_data; "\0" * (@width * @height * 4); end
  def raw_data=(_d); end
  def to_file(_f); end
  def mega?; false; end
  def animated?; false; end
  def playing; false; end
  def method_missing(m, *a); nil; end
  def respond_to_missing?(*); true; end
end

# Generic display object: tracks plain attributes, ignores rendering.
class HeadlessDisplay
  attr_accessor :bitmap, :viewport, :x, :y, :z, :ox, :oy, :zoom_x, :zoom_y, :angle, :mirror,
                :opacity, :blend_type, :visible, :color, :tone, :src_rect, :bush_depth, :wave_amp,
                :wave_length, :wave_speed, :wave_phase, :rect, :contents, :windowskin, :width, :height,
                :active, :pause, :cursor_rect, :back_opacity, :contents_opacity, :openness, :stretch,
                :tileset, :autotiles, :map_data, :priorities, :flash_data, :scroll_x, :scroll_y
  def initialize(*a)
    @viewport = a[0] if a[0].is_a?(Viewport)
    @rect = a[0].is_a?(Rect) ? a[0] : Rect.new(*(a.length == 4 ? a : [0, 0, 512, 384])) if is_a?(Viewport)
    @x = @y = @z = @ox = @oy = 0; @zoom_x = @zoom_y = 1.0; @angle = 0; @opacity = 255; @visible = true
    @color = Color.new(0, 0, 0, 0); @tone = Tone.new; @src_rect = Rect.new; @cursor_rect = Rect.new
    @width = 32; @height = 32; @back_opacity = 255; @contents_opacity = 255; @openness = 255
    @autotiles = []; @disposed = false; @blend_type = 0; @mirror = false; @bush_depth = 0
  end
  def bitmap=(b); @bitmap = b; @src_rect = b ? b.rect : Rect.new; end
  def dispose; @disposed = true; end
  def disposed?; @disposed; end
  def update; end
  def flash(*_a); end
  def method_missing(m, *a)
    n = m.to_s
    return instance_variable_set("@#{n.chomp('=')}", a[0]) if n.end_with?('=')
    instance_variable_get("@#{n}") if instance_variable_defined?("@#{n}")
  end
  def respond_to_missing?(*); true; end
end
class Viewport < HeadlessDisplay; end
class Sprite < HeadlessDisplay; end
class Plane < HeadlessDisplay; end
class Window < HeadlessDisplay; end
class Tilemap < HeadlessDisplay; end

module Graphics
  class << self
    attr_accessor :frame_rate, :frame_count, :brightness, :fullscreen, :scale
    attr_reader :width, :height
    attr_accessor :frame_budget
  end
  @frame_rate = 60; @frame_count = 0; @brightness = 255; @width = 512; @height = 384
  @fullscreen = false; @scale = 1.0; @frame_budget = nil
  class FrameBudgetExceeded < StandardError; end
  def self.update
    @frame_count += 1
    $headless_clock += 1.0 / 60
    $headless_on_frame&.call(@frame_count)
    if @frame_budget && @frame_count > @frame_budget
      raise FrameBudgetExceeded, "frame budget #{@frame_budget} exceeded"
    end
  end
  def self.wait(n); n.times { update }; end
  def self.freeze; end
  def self.transition(*_a); end
  def self.frame_reset; end
  def self.resize_screen(w, h); @width, @height = w, h; end
  def self.snap_to_bitmap; Bitmap.new(@width, @height); end
  def self.screenshot(*_a); end
  def self.center; end
  def self.delta; 1.0 / 60; end
  def self.fadeout(*_a); end
  def self.fadein(*_a); end
  def self.play_movie(*_a); end
end
$headless_clock = 0.0

module Input
  DOWN = 2; LEFT = 4; RIGHT = 6; UP = 8
  A = 11; B = 12; C = 13; X = 14; Y = 15; Z = 16; L = 17; R = 18
  SHIFT = 21; CTRL = 22; ALT = 23; F5 = 25; F6 = 26; F7 = 27; F8 = 28; F9 = 29
  ACTION = A; BACK = B; USE = C; JUMPUP = X; JUMPDOWN = Y; SPECIAL = Z; AUX1 = L; AUX2 = R
  # $input_script: array of buttons; each Input.update pops one as the "pressed" button.
  # $input_auto_confirm: when the script is empty, alternate USE presses so dialogue advances.
  @current = nil
  def self.update
    @current = nil
    if $input_script && !$input_script.empty?
      @current = $input_script.shift
    elsif $input_auto_confirm
      @tick = (@tick || 0) + 1
      @current = USE if @tick.odd?
    end
  end
  def self.press?(b); @current == b; end
  def self.trigger?(b); @current == b; end
  def self.repeat?(b); @current == b; end
  def self.release?(_b); false; end
  def self.dir4; [DOWN, LEFT, RIGHT, UP].include?(@current) ? @current : 0; end
  def self.dir8; dir4; end
  def self.count(_b); 0; end
  def self.time?(_b); 0; end
  def self.pressex?(_k); false; end
  def self.triggerex?(_k); false; end
  def self.repeatex?(_k); false; end
  def self.releaseex?(_k); false; end
  def self.text_input=(_v); end
  def self.gets; ''; end
  def self.mouse_x; 0; end
  def self.mouse_y; 0; end
  def self.mouse_in_window; false; end
  def self.scroll_v; 0; end
  def self.clipboard; ''; end
  def self.clipboard=(_v); end
  def self.raw_key_states; []; end
  def self.controller_raw_button_states; []; end
end

module Audio
  $AUDIO_LOG = []
  %w[bgm se bgs me].each do |k|
    define_singleton_method("#{k}_play") { |*a| $AUDIO_LOG << [k, a[0]] }
    define_singleton_method("#{k}_stop") { |*_a| }
    define_singleton_method("#{k}_fade") { |*_a| }
    define_singleton_method("#{k}_pos") { |*_a| 0 }
    define_singleton_method("#{k}_volume") { |*_a| 100 }
    define_singleton_method("#{k}_set_volume") { |*_a| }
  end
  def self.setup_midi; end
end

module System
  VERSION = '2.4.2/c9378cf'
  def self.uptime; $headless_clock; end
  def self.platform; 'Linux'; end
  def self.is_windows?; false; end
  def self.is_really_windows?; false; end
  def self.is_mac?; false; end
  def self.is_linux?; true; end
  def self.data_directory
    d = ENV['HEADLESS_SAVE_DIR'] || '/tmp/headless_save/'
    Dir.mkdir(d) unless Dir.exist?(d)
    d.end_with?('/') ? d : d + '/'
  end
  def self.game_title; 'FullPoke'; end
  def self.set_window_title(_t); end
  def self.user_language; 'en_US'; end
  def self.user_name; 'Tester'; end
  def self.power_state; { discharging: false, seconds: nil, percent: nil }; end
  def self.reload_cache; end
  def self.mount(*_a); end
  def self.unmount(*_a); end
  def self.launch(*_a); end
  def self.desensitize(f); f; end
  def self.raw_key_states; []; end
  def self.delta; 0; end
  def self.puts(*a); Kernel.puts(*a); end
  def self.nproc; 1; end
  def self.memory; 0; end
  def self.window_title; 'FullPoke'; end
end

module MKXP; end
$MKXP = true

module Kernel
  def msgbox(*a); $stdout.puts "[msgbox] #{a.join(' ')}"; end
end

class Exception
  def message_with_backtrace; "#{message}\n#{backtrace&.first(15)&.join("\n")}"; end
end
class Bitmap
  def self.max_size; 16384; end
end
# mkxp-z's built-in RGSS1 RPG module initializes the bitmap cache hash.
module RPG
  module Cache
    @cache = {}
  end
end
module RPG
  module Cache
    def self.clear
      @cache = {}
    end
  end
end
# mkxp-z animated-bitmap API (static images: one frame).
class Bitmap
  def frame_rate; 0; end
  def frame_count; 1; end
  def current_frame; 0; end
  def play; end
  def stop; end
  def goto_and_stop(_i); end
  def goto_and_play(_i); end
  def looping; false; end
  def looping=(_v); end
end
