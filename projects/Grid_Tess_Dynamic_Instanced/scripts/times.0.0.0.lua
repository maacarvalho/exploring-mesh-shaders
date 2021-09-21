startTimer_0_0_0 = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

	local file = io.open("performance.csv", "a")
    local str = string.gsub(string.format("%d;%d;%d;%f;", 0, 0, 0, timer[1]), "[.]", ",")
	file:write(str)
	file:close()

end

stopTimer_0_0_0 = function()
	local timer = {}
	getAttr("RENDERER", "CURRENT", "TIMER", 0, timer)

    local frame_counter = {}
    getAttr("RENDERER", "CURRENT", "FRAME_COUNT", 0, frame_counter)
	
	local file = io.open("performance.csv", "a");
    local str = string.gsub(string.format("%f;%f\n", timer[1], frame_counter[1]), "[.]", ",")
	file:write(str)
	file:close()

end


