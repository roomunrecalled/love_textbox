local textbox = require("textbox")

local canvas
function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	canvas = love.graphics.newCanvas(192,144)
end

function love.update(dt)

	if (textbox:queue_length() < 1) then
		print("queuing()")
		textbox:queue({"test", "line"}, {small_text=true, line_speed=3, line_pause=3})
	end
	textbox:run(dt,false)

	require("lovebird").update()
end

function love.draw()
	--[[
	love.graphics.print("Hello World,\nHow's it going?\nWell, I hope!", 10, 10)
	--love.graphics.print("Samuel Beechworth went to sea to forget. He wasn't the first and he wouldn't be the last.", 4)
	--love.graphics.print("abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz", 4, 20)
	love.graphics.print(love.graphics.getFont():getHeight(), 80, 40)
	love.graphics.print(love.graphics.getFont():getHeight() * love.graphics.getFont():getLineHeight(), 80, 60)
	love.graphics.draw(image,10,64)
	]]
	textbox:draw(canvas)

	love.graphics.draw(canvas, 0, 0, 0, 4, 4)
end