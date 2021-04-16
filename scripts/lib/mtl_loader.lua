local loader = {}

function loader.load(file_path, filter)

    -- Opening the file
	local fd = io.open(file_path, "r")
    -- Checking if the file exists
	if not fd then error("File not found: " .. file_path) end
    -- Storing .mtl dir
    loader.dir = dirname(file_path)
    -- Return line iterator
	return loader.iter(fd, filter)
end

function loader.iter (fd, filter)
    local line = fd:read()
    return function ()
        while line ~= nil do
            local parsed = loader.parse(line, filter)
            line = fd:read()
            if parsed.type ~= nil then
                return parsed
            end
        end
        return nil
    end
end

function loader.parse(line, filter)

    local l = string_split(line, "%s+")
    if l[1] == "" then table.remove(l, 1) end

    local r = { type = l[1] }

    if filter[l[1]] == nil then return { type = nil } end

    if l[1] == "newmtl" then

        r.m = l[2]

    elseif l[1] == "Kd" then

        r.r = l[2]
        r.g = l[3]
        r.b = l[4]

    elseif l[1] == "map_Kd" then

        r.file = loader.dir..l[2]

    end

    return r

end

function dirname(file_path)

    local l = string_split(file_path, "/")
    local path = ""

    for i=1, #(l)-1 do
        path = path..l[i].."/"
    end

    return path
end

function string_split(s, d)
	local t = {}
	local f
	local match = '(.-)' .. d .. '()'

	if string.find(s, d) == nil then
		return {s}
	end

	for sub, j in string.gmatch(s, match) do
		table.insert(t, sub)
		f = j
	end

    table.insert(t, string.sub(s, f))

	return t
end

return loader
