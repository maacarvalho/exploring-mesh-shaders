init = function()

	local p = {1}
	local vp = {1024, 1024}
	getAttr("RENDERER", "CURRENT", "pixelsPerEdge", 0, p)
	getAttr("VIEWPORT", "MainViewport", "ABSOLUTE_SIZE", 0, vp)

	local l = {0}
	local c = {0}
	l[1] = 3 * math.floor(vp[2] / p[1])
	c[1] = 3 * math.floor(vp[1] / p[1])
	
	p[1] =  l[1] * c[1];
	
	setAttr("PASS", "CURRENT", "INSTANCE_COUNT", 0, p);
	setAttr("RENDERER", "CURRENT", "rows", 0, l);
	setAttr("RENDERER", "CURRENT", "columns", 0, c);
end