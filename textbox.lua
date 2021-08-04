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
local LARGE_FONT_PATH = "assets/fonts/AprilSans/AprilSans-Regular.otf"
local LARGE_FONT_PADDING = {left = 8, top = 4, bottom = 5, right = 4}

local BORDER_PATH = "assets/graphics/textbox_border.png"

-- Sound effects are specified by '#!<symbol>
-- #!!
local EXCLAMATION_SFX_PATH = "assets/sound/xenonn__layered-gunshot-9-edited.wav"
-- #!?
local QUESTION_SFX_PATH = "assets/sound/jack-urbanski__vibraphone-chord-truncated.wav"
-- #!=
local LIGHTBULB_SFX_PATH = "assets/sound/stavsounds__correct2.wav"
-- #!*
local CHIME_SFX_PATH = "assets/sound/mamamucodes__gluckdlow.wav"
-- #!-
local TEXT_SFX_PATH = "assets/sound/yottasounds__typewriter-single-key-type-3.wav"
-- #!_
local ADVANCE_SFX_PATH = "assets/sound/yottasounds__typewriter-single-key-type-3.wav"

local SCREEN_HEIGHT = 144
local SCREEN_WIDTH = 192

-- internal setup
local tb_screen_dim = {height = SCREEN_HEIGHT, width = SCREEN_WIDTH}
local update_tb__,tb_shader__

local tb__ = {
	current__ = nil,
	coroutine__ = nil,
	queue__ = {},
}


tb__.TextboxString = {
	colored_text = {},
	line_speed = 3,
	line_pause = 3,
	screen_shake = false,
	screen_flash = false,
	sound = nil
}
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
	bg_color = DEFAULT_BG_COLOR,
	fg_color = DEFAULT_FG_COLOR,
	font = {
		small = love.graphics.newFont(SMALL_FONT_PATH, 10),
		large = love.graphics.newFont(LARGE_FONT_PATH, 16)
	},
	sound = {
		exclamation = love.audio.newSource(EXCLAMATION_SFX_PATH, "static"),
		question = love.audio.newSource(QUESTION_SFX_PATH, "static"),
		lightbulb = love.audio.newSource(LIGHTBULB_SFX_PATH, "static"),
		chime = love.audio.newSource(CHIME_SFX_PATH, "static"),
		text = love.audio.newSource(TEXT_SFX_PATH, "static"),
		advance = love.audio.newSource(ADVANCE_SFX_PATH, "static")
	},
	line_speed = 3,
	line_pause = 3,
	placement = "bottom",
	small_text = true,
	text_color = DEFAULT_TEXT_COLORS,

	strings = {},

	dimensions = {},
	text_height = 10,
	text_padding = {},
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
		for k,v in pairs(current.strings) do
			love.graphics.setFont(current.small_text and current.font.small or current.font.large)
			love.graphics.printf(
				v, 
				current.text_padding.left, current.dimensions.top + current.text_padding.top + (k-1)*current.text_height,
				tb_screen_dim.width - 4)
		end
		love.graphics.setFont(oldFont)

		-- draw the mask
		if self.current__.mask > 0 then
			love.graphics.setColor(current.fg_color)
			love.graphics.rectangle(
				"fill",
				current.text_padding.left,
				current.dimensions.top + current.dimensions.height - current.text_padding.bottom + 1,
				tb_screen_dim.width - (current.text_padding.left + current.text_padding.right),
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
	local current_font
	if (current.small_text) then
		current_font = current.font.small
		current.text_padding = SMALL_FONT_PADDING 
		current_font:setLineHeight(0.8)
	else
		current_font = current.font.large
		current.text_padding = LARGE_FONT_PADDING 
		current_font:setLineHeight(0.9)
	end

	local text_height = math.floor(current_font:getHeight() * current_font:getLineHeight())
	local tb_height = text_height * 2 + current.text_padding.top + current.text_padding.bottom

	current.dimensions.top = at_bottom and tb_screen_dim.height - tb_height or 0
	current.dimensions.height = tb_height
	current.text_height = text_height

	local function pause__(pause_length)
		local elapsed_time, pause_time = 0, pause_length * .033

		while elapsed_time < pause_time do
			local time = coroutine.yield()
			elapsed_time = elapsed_time + time
		end
	end

	local line_speed = LINE_SPEED[current.line_speed]
	local line_pause = LINE_PAUSE[current.line_pause]

	-- load sounds
	local text_sound = current.sound.text
	local ending_sound = current.sound.exclamation
	text_sound:setVolume(0.5)
	ending_sound:setVolume(0.5)

	-- preprocess colors
	local function convertColor(color_table)
		local result = {}
		for k,v in pairs(color_table) do
			result[k] = v/255
		end
		return result
	end

	current.bg_color = convertColor(current.bg_color)
	current.fg_color = convertColor(current.fg_color)
	for k,v in pairs(current.text_color) do
		current.text_color[k] = convertColor(v)
	end

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
	ending_sound:play()

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

return tb__