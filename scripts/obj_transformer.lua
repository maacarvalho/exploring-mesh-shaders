-- File Path
OBJ_PATH = nil

-- Conversion Parameters
SPLIT_OBJ         = true
CONVERT_NORMALS   = true
CONVERT_MATERIALS = true

-- Types of lines to get from the .obj & .mtl file
OBJ_TYPES = {v = true, vt = true, vn = true, f = true, mtllib = true, usemtl = true}
OBJ_V_TYPES = {v = true, vt = true, vn = true}
OBJ_F_TYPES = {f = true, mtllib = true, usemtl = true}
MTL_TYPES = {newmtl = true, Kd = true, map_Kd = true}

-- File Descriptors
FD_O, FD_TO, FD_MT = nil, nil, nil

-- File Extensions
O_EXT       = ".obj"
TO_EXT      = ".temp.obj"
MT_EXT      = ".materials.buf"

-- Materials
MATERIALS = {}
MATERIALS_IDX = 0
CUR_MATERIAL = ""

-- Removes normals and vertex coordinates from an .obj
stripObj = function ()

    -- Importing .obj & .mtl loader
    local obj_loader = require "lib/obj_loader"
    local mtl_loader = require "lib/mtl_loader"

    if not CONVERT_MATERIALS then
        -- Updating current material
        CUR_MATERIAL = "*"
        -- Storing current material index
        MATERIALS[CUR_MATERIAL] = {idx = MATERIALS_IDX}
        MATERIALS[CUR_MATERIAL].Kd = {r = "0.5", g = "0.5", b = "0.5"}

        -- Getting current material's properties
        local m = MATERIALS[CUR_MATERIAL]

        -- Opening file for the new material
        FD_O = io.open(OBJ_PATH..string.format(".%03d", m.idx)..O_EXT, "w+")
    end


    for parsed_line in obj_loader.load(OBJ_PATH, OBJ_TYPES) do

        local type = parsed_line.type

        if type == "v" then

            -- Writing string to file
            FD_O:write(parsed_line.original, '\n')

        elseif type == "vt" and CONVERT_MATERIALS then

            -- Writing string to file
            FD_O:write(parsed_line.original, '\n')

        elseif type == "vn" and CONVERT_NORMALS then

            -- Writing string to file
            FD_O:write(parsed_line.original, '\n')

        elseif type == "f" then

            local prim_str = "f "
            -- Processing each triangle separately
            for i=1, #(parsed_line.f) do

                local v = parsed_line.f[i]

                prim_str = prim_str..v.vi.."/"
                if CONVERT_MATERIALS then prim_str = prim_str..v.vti end
                prim_str = prim_str.."/"
                if CONVERT_NORMALS then prim_str=prim_str..v.vni end
                prim_str = prim_str.." "

            end

            -- Writing string to file
            FD_O:write(prim_str, '\n')

        elseif type == "mtllib" and CONVERT_MATERIALS then

            -- Processing .mtl file
            for mtl_line in mtl_loader.load(parsed_line.file, MTL_TYPES) do

                if mtl_line.type == "newmtl" then

                    -- Updating current material
                    CUR_MATERIAL = mtl_line.m
                    -- Storing current material index
                    MATERIALS[CUR_MATERIAL] = {idx = MATERIALS_IDX, lib = parsed_line.original, written = false}
                    -- Incrementing the index for the next material
                    MATERIALS_IDX = MATERIALS_IDX + 1

                elseif mtl_line.type == "Kd" then

                    MATERIALS[CUR_MATERIAL].Kd = {
                        r = mtl_line.r,
                        g = mtl_line.g,
                        b = mtl_line.b
                    }

                elseif mtl_line.type == "map_Kd" then

                    MATERIALS[CUR_MATERIAL].map_Kd = mtl_line.file

                end

            end

            -- Opening .materials file
            FD_MT = io.open(OBJ_PATH..MT_EXT, "w+")
            FD_O:write(parsed_line.original, '\n')

        elseif type == "usemtl" and CONVERT_MATERIALS then

            -- Storing current material
            CUR_MATERIAL = parsed_line.m

            -- Getting current material's properties
            local m = MATERIALS[CUR_MATERIAL]

            -- Writing line to .obj
            FD_O:write(parsed_line.original, '\n')

            -- Writing texture to .materials
            if not m.written then

                -- Writing material to files
                FD_MT:write(string.format("%03d", m.idx).." " ..CUR_MATERIAL.." "..m.Kd.r.." "..m.Kd.g.." "..m.Kd.b)
                if m.map_Kd ~= nil then
                    FD_MT:write(" "..m.map_Kd)
                end
                FD_MT:write("\n")

                m.written = true

            end

        end

    end

    if FD_O ~= nil then FD_O:close() end
    if FD_MT ~= nil then FD_MT:close() end

end

-- Converts .obj to several singular purpose files
splitObj = function ()

    -- Importing .obj & .mtl loader
    local obj_loader = require "lib/obj_loader"
    local mtl_loader = require "lib/mtl_loader"

    FD_TO = io.open(OBJ_PATH..TO_EXT, "w+")

    for parsed_line in obj_loader.load(OBJ_PATH, OBJ_V_TYPES) do

        local type = parsed_line.type

        if type == "v" then

            -- Writing string to file
            FD_TO:write(parsed_line.original, '\n')

        elseif type == "vt" and CONVERT_MATERIALS then

            -- Writing string to file
            FD_TO:write(parsed_line.original, '\n')

        elseif type == "vn" and CONVERT_NORMALS then

            -- Writing string to file
            FD_TO:write(parsed_line.original, '\n')

        end
    end

    FD_TO:close()

    for parsed_line in obj_loader.load(OBJ_PATH, OBJ_F_TYPES) do

        local type = parsed_line.type

        if type == "mtllib" then

            -- Processing .mtl file
            for mtl_line in mtl_loader.load(parsed_line.file, MTL_TYPES) do

                if mtl_line.type == "newmtl" then

                    -- Updating current material
                    CUR_MATERIAL = mtl_line.m
                    -- Storing current material index
                    MATERIALS[CUR_MATERIAL] = {idx = MATERIALS_IDX, lib = parsed_line.original, written = false}
                    -- Incrementing the index for the next material
                    MATERIALS_IDX = MATERIALS_IDX + 1

                elseif mtl_line.type == "Kd" then

                    MATERIALS[CUR_MATERIAL].Kd = {
                        r = mtl_line.r,
                        g = mtl_line.g,
                        b = mtl_line.b
                    }

                elseif mtl_line.type == "map_Kd" then

                    MATERIALS[CUR_MATERIAL].map_Kd = mtl_line.file

                end

            end

            -- Opening .materials file
            FD_MT = io.open(OBJ_PATH..MT_EXT, "w+")

        elseif type == "usemtl" then

            -- Storing current material
            CUR_MATERIAL = parsed_line.m

            -- Getting current material's properties
            local m = MATERIALS[CUR_MATERIAL]

            if not m.written then

                -- Writing material to .materials file
                FD_MT:write(string.format("%03d", m.idx).." " ..CUR_MATERIAL.." "..m.Kd.r.." "..m.Kd.g.." "..m.Kd.b)
                if m.map_Kd ~= nil then
                    FD_MT:write(" "..m.map_Kd)
                end
                FD_MT:write("\n")

                -- Creating .obj for this material
                os.execute("cp "..OBJ_PATH..TO_EXT.." "..OBJ_PATH..string.format(".%03d", m.idx)..O_EXT)

                if FD_O ~= nil then FD_O:close() end
                FD_O = io.open(OBJ_PATH..string.format(".%03d", m.idx)..O_EXT, "a")
                FD_O:write(m.lib, '\n')
                FD_O:write(parsed_line.original, '\n')

                m.written = true

            end

            if FD_O ~= nil then FD_O:close() end
            FD_O = io.open(OBJ_PATH..string.format(".%03d", m.idx)..O_EXT, "a")

        elseif type == "f" then

            local prim_str = "f "
            -- Processing each triangle separately
            for i=1, #(parsed_line.f) do

                local v = parsed_line.f[i]

                prim_str = prim_str..v.vi.."/"
                if CONVERT_MATERIALS then prim_str = prim_str..v.vti end
                prim_str = prim_str.."/"
                if CONVERT_NORMALS then prim_str=prim_str..v.vni end
                prim_str = prim_str.." "

            end

            -- Writing string to file
            FD_O:write(prim_str, '\n')

        end

    end

    if FD_O ~= nil then FD_O:close() end
    if FD_MT ~= nil then FD_MT:close() end

end


transformObj = function ()

    if SPLIT_OBJ then

        splitObj()

    else

        stripObj()

    end

end

-- Parses the program arguments
--- FORMAT: lua obj_converter.lua [FLAGS] file.obj
--- FLAGS:
----- [-nn] Makes the conversion ignore the normals
----- [-nm] Makes the conversion ignore the materials
parseArguments = function (arg)

    for i=1, #(arg) - 1 do

        if arg[i] == "-ns" then

            SPLIT_OBJ = false

        elseif arg[i] == "-nn" then

            CONVERT_NORMALS = false

        elseif arg[i] == "-nm" then

            CONVERT_MATERIALS = false

        end

    end

    if not CONVERT_MATERIALS and SPLIT_OBJ then

        print("Can't use both -nm and -ns flags (i.e., can't split an .obj by material and strip the materials)")
        os.exit(1)

    end

    OBJ_PATH = arg[#arg]

end

-- Parsing arguments
parseArguments(arg)

-- Converting file
transformObj()
