-- speed can be either per-line, or per-box
-- screen-shake/color flashes timed to each line
-- ability to change color of text in each line

-- ==Constants==
local LINE_SPEED = {7,4,2,1,0}
local LINE_PAUSE = {24,12,3,1,0}

local DEFAULT_BG_COLOR = {29,43,83}
local DEFAULT_FG_COLOR = {255,241,232}
local DEFAULT_TEXT_COLORS = {{0,0,0}, {41,173,255}, {255,108,36}}

local SMALL_FONT_PATH = "assets/fonts/Poco/Poco.ttf"
local SMALL_FONT_PADDING = {left = 8, top = 0, bottom = 6, right = 4}
local SMALL_FONT_SIZE = 10
local SMALL_FONT_HEIGHT = 0.8
local LARGE_FONT_PATH = "assets/fonts/AprilSans/AprilSans-Regular.otf"
local LARGE_FONT_PADDING = {left = 6, top = 4, bottom = 5, right = 4}
local LARGE_FONT_SIZE = 16
local LARGE_FONT_HEIGHT = 0.9

local BORDER_PATH = "assets/graphics/textbox_border.png"

local SMASH_SFX_PATH = ""
local SHOT_SFX_PATH = "assets/sound/xenonn__layered-gunshot-9-edited.wav"
local CHORD_SFX_PATH = "assets/sound/jack-urbanski__vibraphone-chord-truncated.wav"
local CORRECT_SFX_PATH = "assets/sound/stavsounds__correct2.wav"
local CHIME_SFX_PATH = "assets/sound/mamamucodes__gluckdlow.wav"
local TEXT_SFX_PATH = "assets/sound/yottasounds__typewriter-single-key-type-3.wav"
local ADVANCE_SFX_PATH = "assets/sound/yottasounds__typewriter-single-key-type-3.wav"

local SCREEN_HEIGHT = 144
local SCREEN_WIDTH = 192

local tb_screen_dim = {height = SCREEN_HEIGHT, width = SCREEN_WIDTH}
local update_tb__,tb_shader__

local tb__ = {
	current__ = nil,
	coroutine__ = nil,
	queue__ = {},
}

-- internal setup
function tb__:init()
	-- pre-process sounds
	local default_sound = {
			exclamation = love.audio.newSource(SHOT_SFX_PATH, "static"),
			question = love.audio.newSource(CHORD_SFX_PATH, "static"),
			lightbulb = love.audio.newSource(CORRECT_SFX_PATH, "static"),
			chime = love.audio.newSource(CHIME_SFX_PATH, "static"),
			text = love.audio.newSource(TEXT_SFX_PATH, "static"),
			advance = love.audio.newSource(ADVANCE_SFX_PATH, "static")
	}

	for k,v in pairs(default_sound) do
		v:setVolume(0.5)
	end

	-- pre-process default colors
	local function convertColor(color_table)
		local result = {}
		for k,v in pairs(color_table) do
			result[k] = v/255
		end
		return result
	end

	local default_color = {
		bg = DEFAULT_BG_COLOR,
		fg = DEFAULT_FG_COLOR,
		text = DEFAULT_TEXT_COLORS,
	}
	default_color.bg = convertColor(default_color.bg)
	default_color.fg = convertColor(default_color.fg)
	for k,v in pairs(default_color.text) do
		default_color.text[k] = convertColor(v)
	end

	local default_font = {
		small = {
			font = love.graphics.newFont(SMALL_FONT_PATH, SMALL_FONT_SIZE),
			padding = SMALL_FONT_PADDING
		},
		large = {
			font = love.graphics.newFont(LARGE_FONT_PATH, LARGE_FONT_SIZE),
			padding = LARGE_FONT_PADDING
		}
	}
	default_font.small.font:setLineHeight(SMALL_FONT_HEIGHT)
	default_font.small.text_height =
		math.floor(default_font.small.font:getHeight() *
							 default_font.small.font:getLineHeight())
	default_font.large.font:setLineHeight(LARGE_FONT_HEIGHT)
	default_font.large.text_height =
		math.floor(default_font.large.font:getHeight() * 
							 default_font.large.font:getLineHeight())

	-- initialize TextboxString class
	tb__.TextboxString = {
		colored_text = default_color.text_color,
		line_speed = 3,
		line_pause = 3,
		screen_shake = false,
		screen_flash = false,
		sound = nil
	}

	-- define 'pause' function
	local function pause__(pause_length)
		local elapsed_time, pause_time = 0, pause_length * .033

		while elapsed_time < pause_time do
			local time = coroutine.yield()
			elapsed_time = elapsed_time + time
		end
	end

	function tb__.TextboxString:new(string, options)
		options = options or {}

		-- process string and set flags
		--options.colored_text = string
		local string_i = 1;
		local current_substring
		if (string[string_i] == "#") then
			string_i = string_i + 1
			while (string_i < #string) do
				-- scroll speed 's<num>'
				-- pause speed 'p<num>'
				-- screenshake '<>'
				-- screenflash '!!'
			end
		end
		while (string_i < #string) do

		end
		local colored_text = {}

		setmetatable(options, self)
		self.__index = self
		return options
	end

	tb__.Textbox = {
		bg_color = default_color.bg,
		fg_color = default_color.fg,
		font = default_font,
		sound = default_sound,
		line_speed = 3,
		line_pause = 3,
		placement = "bottom",
		small_text = true,
		text_color = default_color.text,

		strings = {},

		dimensions = {},
		completed = false,
		mask = nil
	}

	function tb__.Textbox:new(o)
		o = o or {}
		setmetatable(o, self)
		self.__index = self
		return o
	end

	function tb__:queue_length()
		return #self.queue__
	end

	function tb__:queue(strings, options)
		local new_textbox = options or {}
		new_textbox.strings = strings
		table.insert(self.queue__, self.Textbox:new(new_textbox))
	end

	function tb__:run(dt, close_textbox)
		local ok, message
		if not self.coroutine__ then
			if #self.queue__ > 0 then
				self.current__ = self.queue__[1]
				self.coroutine__ = coroutine.create(update_tb__)
				ok, message = coroutine.resume(self.coroutine__, dt)
			end
		elseif coroutine.status(self.coroutine__) ~= "dead" then
			ok, message = coroutine.resume(self.coroutine__, dt, close_textbox)
		else
			table.remove(self.queue__, 1)
			self.coroutine__ = nil
			self.current__ = nil
		end
		print(self.current__)
		if not ok then
			print(message)
		end
	end

	local function draw_textbox()
	end
	function tb__:draw(screencanvas, textcanvas)
		local current = self.current__
		local old_color = {love.graphics.getColor()}
		if current and current.mask then
			-- draw the textbox
			love.graphics.setColor(current.bg_color)
			love.graphics.rectangle("fill",
				0,
				current.dimensions.top,
				tb_screen_dim.width,
				current.dimensions.height)

			love.graphics.setColor(current.fg_color)
			love.graphics.rectangle("fill",
				2,
				current.dimensions.top + 2,
				tb_screen_dim.width - 4,
				current.dimensions.height - 4)

			local oldFont = love.graphics.getFont()
			-- print the text
			love.graphics.setColor(current.text_color[1])
			local current_font =
				current.small_text and current.font.small or current.font.large
			love.graphics.setFont(current_font.font)
			for k,v in pairs(current.strings) do
				love.graphics.printf(
					v, 
					current_font.padding.left,
					current.dimensions.top + current_font.padding.top + (k-1)*current_font.text_height,
					tb_screen_dim.width - 4)
			end
			love.graphics.setFont(oldFont)

			-- draw the mask
			if self.current__.mask > 0 then
				love.graphics.setColor(current.fg_color)
				love.graphics.rectangle(
					"fill",
					current_font.padding.left,
					current.dimensions.top + current.dimensions.height - current_font.padding.bottom + 1,
					tb_screen_dim.width - (current_font.padding.left + current_font.padding.right),
					-current.mask)
			end
			-- draw the 'continue' symbol
			if self.current__.completed then
				love.graphics.setColor(current.text_color[1])
				love.graphics.circle("line", tb_screen_dim.width - 10, tb_screen_dim.height - 10, 2)
			end
		end

		if old_color then
			love.graphics.setColor(old_color)
		end
	end

	update_tb__ = function ()
		local tb_close = false
		local current = tb__.current__

		local at_bottom = current.placement == "bottom"
		local current_font =
			current.small_text and current.font.small or current.font.large
		local text_height = current_font.text_height
		local tb_height =
			text_height * 2 + current_font.padding.top + current_font.padding.bottom

		current.dimensions.top = at_bottom and tb_screen_dim.height - tb_height or 0
		current.dimensions.height = tb_height

		local line_speed = LINE_SPEED[current.line_speed]
		local line_pause = LINE_PAUSE[current.line_pause]

		-- load sounds
		local text_sound = current.sound.text
		local ending_sound = current.sound.text

		pause__(4)

		current.mask = text_height * 2
		while current.mask > text_height do
			current.mask = current.mask - 1
			if current.mask == math.floor(text_height * 1.5) then
				text_sound:stop()
				text_sound:play()
			end
			pause__(line_speed)
		end

		ending_sound:stop()
		--ending_sound:play()
		text_sound:play()

		pause__(line_pause)
		if current.line_pause > 3 then
			current.mask = current.mask - (current.line_pause - 2)
		end

		if (#current.strings > 1) then
			while current.mask > 0 do
				current.mask = current.mask - 1
				if current.mask == math.floor(text_height * 0.5) then
					text_sound:stop()
					text_sound:play()
				end
				pause__(line_speed)
			end
		end

		ending_sound:stop()
		ending_sound:play()

		pause__(16)
		current.completed = true

		while not tb_close do
			_, tb_close = coroutine.yield()
		end

		pause__(2)

		current.sound.advance:play()
	end
end

return tb__