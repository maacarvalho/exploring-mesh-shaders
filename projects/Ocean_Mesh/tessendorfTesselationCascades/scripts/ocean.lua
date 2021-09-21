oceanTypeChanged = function()

	local att = { -- wavelengths 475, 525, 700
		98.2, 95.8, 57.0, -- I
		97.5, 95.3, 56.5, -- IA
		96.8, 94.7, 56.0, -- IB
		94.0, 92.7, 54.0, -- II
		89.0, 89.0, 52.0, -- III
		84.0, 88.0, 52.0, -- 1
		75.0, 82.0, 49.0, -- 3
		65.0, 73.0, 45.0, -- 5
		49.0, 61.0, 40.0, -- 7
		29.0, 46.0, 33.0  -- 9
	}
	
	local t = {}
	getAttr("RENDERER", "CURRENT", "oceanType", 0, t)
	t[1] = t[1] - 1
	local trans = {att[t[1]*3+1], att[t[1]*3+2], att[t[1]*3+3]}
	setAttr("RENDERER", "CURRENT", "oceanTrans", 0, trans);
end


oceanConfigChanged = function()

	local f = {0}
	
	setAttr("RENDERER", "CURRENT", "FRAME_COUNT", 0, f)
end
