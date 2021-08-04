local tbs_parser__ = {}

local function parse__(string)
	if #string < 1 then
		error("empty string")
	end

	local index = 1
	local current_char = string[index]
	if (current_char == "#") then
		while (index <= #string and current_char ~= " ") do
			-- body
		end
	end
end

function tbs_parser__.parse(string)
	local ok, result = pcall(parse__, string)

	if ok then
		return result
	else
		print(result)
	end
end

return tbs_parser__