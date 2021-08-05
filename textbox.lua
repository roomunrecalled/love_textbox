-- speed can be either per-line, or per-box
-- screen-shake/color flashes timed to each line
-- ability to change color of text in each line

-- ==Constants==
local LINE_SPEED = {7,4,2,1,0}
local LINE_PAUSE = {24,12,3,1,0}

local DEFAULT_BG_COLOR = {29,43,83}
local DEFAULT_FG_COLOR = {255,241,232}
local DEFAULT_TEXT_COLORS = {{0,0,0}, {41,173,255}, {255,108,36}}

local TEXTBOX_MARGIN = {left = 4, right = 2}

local SMALL_FONT_PATH = "assets/fonts/Poco/Poco.ttf"
local SMALL_FONT_PADDING = {left = 8, top = 0, bottom = 6, right = 4}
local SMALL_FONT_SIZE = 10
local SMALL_FONT_HEIGHT = 0.8
local LARGE_FONT_PATH = "assets/fonts/AprilSans/AprilSans-Regular.otf"
local LARGE_FONT_PADDING = {left = 6, top = 4, bottom = 5, right = 4}
local LARGE_FONT_SIZE = 16
local LARGE_FONT_HEIGHT = 0.9

local BORDER_PATH = "assets/graphics/textbox_border.png"
local ADVANCE_SYMBOL_PATH = ""

local SMASH_SFX_PATH = ""
local SHOT_SFX_PATH = "assets/sound/xenonn__layered-gunshot-9-edited.wav"
local CHORD_SFX_PATH = "assets/sound/jack-urbanski__vibraphone-chord-truncated.wav"
local CORRECT_SFX_PATH = "assets/sound/stavsounds__correct2.wav"
local CHIME_SFX_PATH = "assets/sound/mamamucodes__gluckdlow.wav"
local TEXT_SFX_PATH = "assets/sound/yottasounds__typewriter-single-key-type-3.wav"
local ADVANCE_SFX_PATH = "assets/sound/yottasounds__typewriter-single-key-type-3.wav"

local SCREEN_HEIGHT = 144
local SCREEN_WIDTH = 192

local tb__ = {
	current__ = nil,
	coroutine__ = nil,
	queue__ = {},
}

-- internal setup
local init_tb_defaults__
function tb__:init()
	local tb_screen_dim = {height = SCREEN_HEIGHT, width = SCREEN_WIDTH}
	local update_tb__
	local tb_shader__

	init_tb_defaults__(self)
	-- initialize TextboxString class
	self.TextboxString = {
		colored_text = self.default_color.text_color,
		line_speed = 3,
		line_pause = 3,
		screen_shake = "none",
		screen_flash = "none",
		sound = "none",
		effect = "none"
	}

	function self.TextboxString:new(string, options)
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

	self.Textbox = {
		bg_color = self.default_color.bg,
		fg_color = self.default_color.fg,
		font = self.default_font,
		sound = self.default_sound,
		line_speed = 3,
		line_pause = 3,
		placement = "bottom",
		small_text = true,
		text_color = self.default_color.text,

		strings = {},

		dimensions = {},
		completed = false,
		mask = nil
	}

	function self.Textbox:new(o)
		o = o or {}
		setmetatable(o, self)
		self.__index = self
		return o
	end

	function self:queue_length()
		return #self.queue__
	end

	function self:queue(strings, options)
		local new_textbox = options or {}
		new_textbox.strings = strings
		table.insert(self.queue__, self.Textbox:new(new_textbox))
	end

	function self:run(dt, close_textbox)
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

	local draw_textbox__, print_text__, draw_mask__
	function self:draw(screencanvas, textcanvas)
		local current = self.current__
		local old_color = {love.graphics.getColor()}
		if current and current.mask then
			-- draw the textbox
			draw_textbox__(current)

			-- print the text
			local current_font =
				current.small_text and current.font.small or current.font.large
			print_text__(current, current_font)

			-- draw the mask
			draw_mask__(current, current_font)

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

	local tb_pause__, display_line__
	update_tb__ = function ()
		local tb_close = false
		local current = self.current__

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

		tb_pause__(4)

		current.mask = text_height * 2

		-- display the first line
		display_line__(current, nil, text_height * 2, text_height)

		tb_pause__(line_pause)
		if current.line_pause > 3 then
			current.mask = current.mask - (current.line_pause - 2)
		end

		-- display the second line
		if (#current.strings > 1) then
			display_line__(current, nil, text_height, 0)
		end

		tb_pause__(16)
		current.completed = true

		while not tb_close do
			_, tb_close = coroutine.yield()
		end

		tb_pause__(2)

		current.sound.advance:play()
	end

	-- tb:draw() helper functions
	draw_textbox__ = function(textbox)
		love.graphics.setColor(textbox.bg_color)
		love.graphics.rectangle("fill",
			TEXTBOX_MARGIN.left,
			textbox.dimensions.top,
			tb_screen_dim.width - (TEXTBOX_MARGIN.left + TEXTBOX_MARGIN.right),
			textbox.dimensions.height)

		love.graphics.setColor(textbox.fg_color)
		-- this is supposed to be replaced with a sprite, so magic numbers are fine
		love.graphics.rectangle("fill",
			TEXTBOX_MARGIN.left + 2,
			textbox.dimensions.top + 2,
			tb_screen_dim.width - (TEXTBOX_MARGIN.left + TEXTBOX_MARGIN.right) - 4,
			textbox.dimensions.height - 4)
	end
	print_text__ = function(textbox, current_font)
		local oldFont = love.graphics.getFont()
		love.graphics.setFont(current_font.font)
		love.graphics.setColor(textbox.text_color[1])
		for k,v in pairs(textbox.strings) do
			love.graphics.printf(
				v, 
				TEXTBOX_MARGIN.left + current_font.padding.left,
				textbox.dimensions.top + current_font.padding.top + (k-1)*current_font.text_height,
				tb_screen_dim.width - 4)
		end
		love.graphics.setFont(oldFont)
	end
	draw_mask__ = function(textbox, current_font)
		if textbox.mask > 0 then
			love.graphics.setColor(textbox.fg_color)
			love.graphics.rectangle(
				"fill",
				TEXTBOX_MARGIN.left + current_font.padding.left,
				textbox.dimensions.top + textbox.dimensions.height - current_font.padding.bottom + 2,
				tb_screen_dim.width -
					(TEXTBOX_MARGIN.left + TEXTBOX_MARGIN.right) -
					(current_font.padding.left + current_font.padding.right),
				-textbox.mask)
		end
	end

	-- update_tb__ helper functions
	tb_pause__ = function(pause_length)
		local elapsed_time, pause_time = 0, pause_length * .033

		while elapsed_time < pause_time do
			local time = coroutine.yield()
			elapsed_time = elapsed_time + time
		end
	end

	display_line__ = function(textbox, line, max, min)
		local text_sfx = textbox.sound.text
		local sfx = textbox.sound.text
		while textbox.mask > min do
			textbox.mask = textbox.mask - 1
			if textbox.mask == math.floor((max + min) * 0.52) then
				text_sfx:stop()
				text_sfx:play()
			end
			-- TODO: change to line
			tb_pause__(LINE_SPEED[textbox.line_speed])
		end

		sfx:stop()
		sfx:play()
	end
end

-- init function for tb__. Yes this is messy.
init_tb_defaults__ = function(self)
	-- load and pre-process sounds
	self.default_sound = {
			exclamation = love.audio.newSource(SHOT_SFX_PATH, "static"),
			question = love.audio.newSource(CHORD_SFX_PATH, "static"),
			lightbulb = love.audio.newSource(CORRECT_SFX_PATH, "static"),
			chime = love.audio.newSource(CHIME_SFX_PATH, "static"),
			text = love.audio.newSource(TEXT_SFX_PATH, "static"),
			advance = love.audio.newSource(ADVANCE_SFX_PATH, "static")
	}

	for k,v in pairs(self.default_sound) do
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

	self.default_color = {
		bg = DEFAULT_BG_COLOR,
		fg = DEFAULT_FG_COLOR,
		text = DEFAULT_TEXT_COLORS,
	}
	self.default_color.bg = convertColor(self.default_color.bg)
	self.default_color.fg = convertColor(self.default_color.fg)
	for k,v in pairs(self.default_color.text) do
		self.default_color.text[k] = convertColor(v)
	end

	self.default_font = {
		small = {
			font = love.graphics.newFont(SMALL_FONT_PATH, SMALL_FONT_SIZE),
			padding = SMALL_FONT_PADDING
		},
		large = {
			font = love.graphics.newFont(LARGE_FONT_PATH, LARGE_FONT_SIZE),
			padding = LARGE_FONT_PADDING
		}
	}
	self.default_font.small.font:setLineHeight(SMALL_FONT_HEIGHT)
	self.default_font.small.text_height =
		math.floor(self.default_font.small.font:getHeight() *
								self.default_font.small.font:getLineHeight())
	self.default_font.large.font:setLineHeight(LARGE_FONT_HEIGHT)
	self.default_font.large.text_height =
		math.floor(self.default_font.large.font:getHeight() *
								self.default_font.large.font:getLineHeight())
end

return tb__