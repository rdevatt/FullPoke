# RGSS1 data classes (as documented in the RPG Maker XP help file) plus Table/Color/Tone
# with byte-compatible _dump/_load, so maps saved here open normally in RPG Maker XP.
class Table
  attr_reader :xsize, :ysize, :zsize
  def initialize(x, y = 0, z = 0)
    @dim = 1 + (y > 0 ? 1 : 0) + (z > 0 ? 1 : 0)
    @xsize, @ysize, @zsize = x, [y, 1].max, [z, 1].max
    @data = Array.new(@xsize * @ysize * @zsize, 0)
  end
  def self._load(s)
    dim, x, y, z, _n = s[0, 20].unpack('l<5')
    t = allocate
    t.instance_variable_set(:@dim, dim)
    t.instance_variable_set(:@xsize, x); t.instance_variable_set(:@ysize, y); t.instance_variable_set(:@zsize, z)
    t.instance_variable_set(:@data, s[20..].unpack('s<*'))
    t
  end
  def _dump(_l = -1)
    [@dim || 3, @xsize, @ysize, @zsize, @data.size].pack('l<5') + @data.pack('s<*')
  end
  def [](x, y = 0, z = 0)
    return nil if x >= @xsize || y >= @ysize || z >= @zsize || x < 0 || y < 0 || z < 0
    @data[x + y * @xsize + z * @xsize * @ysize]
  end
  def []=(*a)
    v = a.pop; x, y, z = a; y ||= 0; z ||= 0
    return if x >= @xsize || y >= @ysize || z >= @zsize
    @data[x + y * @xsize + z * @xsize * @ysize] = v
  end
  def resize(x, y = 0, z = 0)
    old = self.dup; old_data = @data
    ox, oy, oz = @xsize, @ysize, @zsize
    initialize(x, y, z)
    [ox, @xsize].min.times { |i| [oy, @ysize].min.times { |j| [oz, @zsize].min.times { |k| @data[i + j * @xsize + k * @xsize * @ysize] = old_data[i + j * ox + k * ox * oy] } } }
  end
  def raw; @data; end
end
class Color
  attr_accessor :red, :green, :blue, :alpha
  def initialize(r = 0, g = 0, b = 0, a = 255); @red, @green, @blue, @alpha = r.to_f, g.to_f, b.to_f, a.to_f; end
  def self._load(s); new(*s.unpack('E4')); end
  def _dump(_l = -1); [@red, @green, @blue, @alpha].pack('E4'); end
end
class Tone
  attr_accessor :red, :green, :blue, :gray
  def initialize(r = 0, g = 0, b = 0, gr = 0); @red, @green, @blue, @gray = r.to_f, g.to_f, b.to_f, gr.to_f; end
  def self._load(s); new(*s.unpack('E4')); end
  def _dump(_l = -1); [@red, @green, @blue, @gray].pack('E4'); end
end

module RPG
  class Map
    attr_accessor :tileset_id, :width, :height, :autoplay_bgm, :bgm, :autoplay_bgs, :bgs,
                  :encounter_list, :encounter_step, :data, :events
    def initialize(width, height)
      @tileset_id = 1; @width = width; @height = height
      @autoplay_bgm = false; @bgm = RPG::AudioFile.new; @autoplay_bgs = false
      @bgs = RPG::AudioFile.new('', 80); @encounter_list = []; @encounter_step = 30
      @data = Table.new(width, height, 3); @events = {}
    end
  end
  class MapInfo
    attr_accessor :name, :parent_id, :order, :expanded, :scroll_x, :scroll_y
    def initialize; @name = ''; @parent_id = 0; @order = 0; @expanded = false; @scroll_x = 0; @scroll_y = 0; end
  end
  class Event
    attr_accessor :id, :name, :x, :y, :pages
    def initialize(x, y); @id = 0; @name = ''; @x = x; @y = y; @pages = [RPG::Event::Page.new]; end
    class Page
      attr_accessor :condition, :graphic, :move_type, :move_speed, :move_frequency, :move_route,
                    :walk_anime, :step_anime, :direction_fix, :through, :always_on_top, :trigger, :list
      def initialize
        @condition = Condition.new; @graphic = Graphic.new; @move_type = 0; @move_speed = 3
        @move_frequency = 3; @move_route = RPG::MoveRoute.new; @walk_anime = true; @step_anime = false
        @direction_fix = false; @through = false; @always_on_top = false; @trigger = 0
        @list = [RPG::EventCommand.new]
      end
      class Condition
        attr_accessor :switch1_valid, :switch2_valid, :variable_valid, :self_switch_valid,
                      :switch1_id, :switch2_id, :variable_id, :variable_value, :self_switch_ch
        def initialize
          @switch1_valid = false; @switch2_valid = false; @variable_valid = false; @self_switch_valid = false
          @switch1_id = 1; @switch2_id = 1; @variable_id = 1; @variable_value = 0; @self_switch_ch = 'A'
        end
      end
      class Graphic
        attr_accessor :tile_id, :character_name, :character_hue, :direction, :pattern, :opacity, :blend_type
        def initialize
          @tile_id = 0; @character_name = ''; @character_hue = 0; @direction = 2; @pattern = 0
          @opacity = 255; @blend_type = 0
        end
      end
    end
  end
  class EventCommand
    attr_accessor :code, :indent, :parameters
    def initialize(code = 0, indent = 0, parameters = []); @code = code; @indent = indent; @parameters = parameters; end
  end
  class MoveRoute
    attr_accessor :repeat, :skippable, :list
    def initialize; @repeat = true; @skippable = false; @list = [RPG::MoveCommand.new]; end
  end
  class MoveCommand
    attr_accessor :code, :parameters
    def initialize(code = 0, parameters = []); @code = code; @parameters = parameters; end
  end
  class AudioFile
    attr_accessor :name, :volume, :pitch
    def initialize(name = '', volume = 100, pitch = 100); @name = name; @volume = volume; @pitch = pitch; end
  end
  class Tileset
    attr_accessor :id, :name, :tileset_name, :autotile_names, :panorama_name, :panorama_hue,
                  :fog_name, :fog_hue, :fog_opacity, :fog_blend_type, :fog_zoom, :fog_sx, :fog_sy,
                  :battleback_name, :passages, :priorities, :terrain_tags
    def initialize
      @id = 0; @name = ''; @tileset_name = ''; @autotile_names = [''] * 7; @panorama_name = ''
      @panorama_hue = 0; @fog_name = ''; @fog_hue = 0; @fog_opacity = 64; @fog_blend_type = 0
      @fog_zoom = 200; @fog_sx = 0; @fog_sy = 0; @battleback_name = ''
      @passages = Table.new(384); @priorities = Table.new(384); @priorities[0] = 5
      @terrain_tags = Table.new(384)
    end
  end
  class CommonEvent
    attr_accessor :id, :name, :trigger, :switch_id, :list
    def initialize; @id = 0; @name = ''; @trigger = 0; @switch_id = 1; @list = [RPG::EventCommand.new]; end
  end
  class System
    attr_accessor :magic_number, :party_members, :elements, :switches, :variables, :windowskin_name,
                  :title_name, :gameover_name, :battle_transition, :title_bgm, :battle_bgm, :battle_end_me,
                  :gameover_me, :cursor_se, :decision_se, :cancel_se, :buzzer_se, :equip_se, :shop_se,
                  :save_se, :load_se, :battle_start_se, :escape_se, :actor_collapse_se, :enemy_collapse_se,
                  :words, :test_battlers, :test_troop_id, :start_map_id, :start_x, :start_y,
                  :battleback_name, :battler_name, :battler_hue, :edit_map_id
    class Words
      attr_accessor :gold, :hp, :sp, :str, :dex, :agi, :int, :atk, :pdef, :mdef, :weapon, :armor1,
                    :armor2, :armor3, :armor4, :attack, :skill, :guard, :item, :equip
    end
    class TestBattler
      attr_accessor :actor_id, :level, :weapon_id, :armor1_id, :armor2_id, :armor3_id, :armor4_id
    end
  end
  # Database classes Essentials never uses; loaded only so Marshal round-trips them.
  class GenericData
    def method_missing(m, *a)
      n = m.to_s
      return instance_variable_set("@#{n.chomp('=')}", a[0]) if n.end_with?('=')
      instance_variable_get("@#{n}")
    end
    def respond_to_missing?(*); true; end
  end
  %w[Actor Skill Item Weapon Armor Enemy Troop State Animation].each { |c| const_set(c, ::Class.new(GenericData)) }
  const_set(:Class, ::Class.new(GenericData))
  RPG::Class.const_set(:Learning, ::Class.new(GenericData))
  RPG::Enemy.const_set(:Action, ::Class.new(GenericData))
  RPG::Troop.const_set(:Member, ::Class.new(GenericData))
  RPG::Troop.const_set(:Page, ::Class.new(GenericData))
  RPG::Troop::Page.const_set(:Condition, ::Class.new(GenericData))
  RPG::Animation.const_set(:Frame, ::Class.new(GenericData))
  RPG::Animation.const_set(:Timing, ::Class.new(GenericData))
end
