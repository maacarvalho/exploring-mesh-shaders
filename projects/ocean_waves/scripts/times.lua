stopTimer = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

    local frame_counter = {}
    getAttr("RENDERER", "CURRENT", "FRAME_COUNT", 0, frame_counter)

	local file = io.open("performance.csv", "a");
    local str = string.gsub(string.format("%f;%f\n", timer[1], frame_counter[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_trad = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format(";%s;%f;", "Traditional", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end


startTimer_256_1x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 256, "1x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_256_2x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 256, "2x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end


startTimer_256_4x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 256, "4x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_256_8x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 256, "8x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_256_16x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 256, "16x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_256_32x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 256, "32x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_128_1x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 128, "1x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_128_2x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 128, "2x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end


startTimer_128_4x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 128, "4x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_128_8x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 128, "8x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_128_16x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 128, "16x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_128_32x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 128, "32x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end


startTimer_64_1x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 64, "1x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_64_2x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 64, "2x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end


startTimer_64_4x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 64, "4x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_64_8x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 64, "8x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_64_16x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 64, "16x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_64_32x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 64, "32x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end


startTimer_32_1x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 32, "1x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_32_2x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 32, "2x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end


startTimer_32_4x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 32, "4x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_32_8x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 32, "8x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_32_16x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 32, "16x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

startTimer_32_32x = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%s;%f;", 32, "32x", timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end