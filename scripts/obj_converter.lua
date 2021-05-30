-- File Path
OBJ_PATH = nil

-- Conversion Parameters
CONVERT_NORMALS   = true
CONVERT_MATERIALS = true

-- File Extensions
V_EXT       = ".vertices.buf"
VT_EXT      = ".texcoords.buf"
VN_EXT      = ".normals.buf"
I_EXT       = ".indices.buf"
P_EXT       = ".primitives.buf"
M_EXT       = ".meshlets.buf"
MT_EXT      = ".materials.buf"

-- Types of lines to get from the .obj & .mtl file
OBJ_TYPES = {v = true, vt = true, vn = true, f = true, mtllib = true, usemtl = true}
MTL_TYPES = {newmtl = true, Kd = true, map_Kd = true}

-- File Descriptors
FD_V, FD_VT, FD_VN, FD_I, FD_P, FD_M, FD_MT = nil, nil, nil, nil, nil, nil, nil

-- Meshlet properties
CACHE_SIZE                = 98304
N_WARPS                   = 4
MAX_MESHLET_SIZE          = CACHE_SIZE / N_WARPS
--MAX_MESHLET_SIZE          = 168
MAX_MESHLET_PRIMITIVES    = 32
MAX_MESHLET_VERTICES      = 32

-- Size of a vertex
GEOMETRY_SIZE             = 0
NORMALS_SIZE              = 0
TEXCOORDS_SIZE            = 0

MESHLET_SIZE              = 4

-- Size of data types
FLOAT_SIZE = 4

-- Materials
MATERIALS = {}
MATERIALS_IDX = 0
CUR_MATERIAL = ""

-- Current Meshlet properties by Material
MESHLETS = {}
MESHLETS[CUR_MATERIAL] = {}
MESHLETS[CUR_MATERIAL].SIZE = MESHLET_SIZE * FLOAT_SIZE
MESHLETS[CUR_MATERIAL].INDICES_DICT = {}
MESHLETS[CUR_MATERIAL].INDICES_OFFSET = 0
MESHLETS[CUR_MATERIAL].INDICES_COUNT = 0
MESHLETS[CUR_MATERIAL].PRIMITIVES_OFFSET = 0
MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT = 0

-- Handles adding the primitive to a meshlet
write_primitive = function (prim)

    -- Updating meshlet size to check if it doesn't go above the expected
    local updated_meshlet_size = MESHLETS[CUR_MATERIAL].SIZE
    local updated_meshlet_indices_count = MESHLETS[CUR_MATERIAL].INDICES_COUNT
    local updated_meshlet_primitives_count = MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT

    updated_meshlet_size = updated_meshlet_size + 3 * FLOAT_SIZE -- A primitive is composed of 3 indices

    -- Checking how each vertex increments the size of the meshlet
    for _, v in ipairs(prim) do

        local v_key = v.vi
        if v.vni and CONVERT_NORMALS then v_key = v_key.." "..v.vni end
        if v.vti and CONVERT_MATERIALS then v_key = v_key.." "..v.vti end

        if MESHLETS[CUR_MATERIAL].INDICES_DICT[v_key] == nil then
            -- Updating meshlet size accordingly
            updated_meshlet_size = updated_meshlet_size +
                (GEOMETRY_SIZE + NORMALS_SIZE + TEXCOORDS_SIZE) * FLOAT_SIZE -- Vertex Data
            updated_meshlet_size = updated_meshlet_size + 3 * FLOAT_SIZE -- Indices
            updated_meshlet_indices_count = updated_meshlet_indices_count + 1

        end

        updated_meshlet_primitives_count = updated_meshlet_primitives_count + 1

    end

    -- Checking if adding the primitive to the meshlet makes it's size be above the batch size
    if updated_meshlet_size > MAX_MESHLET_SIZE or -- Can't go over cache size
        updated_meshlet_indices_count > MAX_MESHLET_VERTICES or -- Can't output over the max_vertices
        updated_meshlet_primitives_count / 3 > MAX_MESHLET_PRIMITIVES then -- Can't output over the max_primitives

        -- Writing meshlet information & adding lines to indices and primitives
        if FD_I ~= nil then FD_I:write("\n") end
        if FD_P ~= nil then FD_P:write("\n") end
        if FD_M ~= nil then FD_M:write(
            MESHLETS[CUR_MATERIAL].INDICES_OFFSET.." "..MESHLETS[CUR_MATERIAL].INDICES_COUNT.." "..
            MESHLETS[CUR_MATERIAL].PRIMITIVES_OFFSET.." "..MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT.."\n")
        end

        -- Resetting current meshlet info
        MESHLETS[CUR_MATERIAL].SIZE = MESHLET_SIZE * FLOAT_SIZE
        MESHLETS[CUR_MATERIAL].INDICES_OFFSET = MESHLETS[CUR_MATERIAL].INDICES_OFFSET + MESHLETS[CUR_MATERIAL].INDICES_COUNT
        MESHLETS[CUR_MATERIAL].INDICES_DICT = {}
        MESHLETS[CUR_MATERIAL].INDICES_COUNT = 0
        MESHLETS[CUR_MATERIAL].PRIMITIVES_OFFSET = MESHLETS[CUR_MATERIAL].PRIMITIVES_OFFSET + MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT
        MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT = 0

        return write_primitive(prim)

    else

        for _, v in ipairs(prim) do

            local v_key = v.vi
            if v.vni and CONVERT_NORMALS then v_key = v_key.." "..v.vni end
            if v.vti and CONVERT_MATERIALS then v_key = v_key.." "..v.vti end

            if MESHLETS[CUR_MATERIAL].INDICES_DICT[v_key] == nil then
                -- Associating the global vertex index to the meshlet index
                MESHLETS[CUR_MATERIAL].INDICES_DICT[v_key] = MESHLETS[CUR_MATERIAL].INDICES_COUNT
                -- Incrementing the number of unique vertices currently in the mesh
                MESHLETS[CUR_MATERIAL].INDICES_COUNT = MESHLETS[CUR_MATERIAL].INDICES_COUNT + 1

                -- Writing index
                if FD_I == nil then FD_I = io.open(OBJ_PATH..I_EXT, "w+") end
                FD_I:write((v.vi - 1).." ")
                if v.vni and CONVERT_NORMALS then FD_I:write((v.vni - 1).." ") else FD_I:write((-1).." ") end
                if v.vti and CONVERT_MATERIALS then FD_I:write((v.vti - 1).." ") else FD_I:write((-1).." ") end
            end

            -- Incrementing the number of primitives currently in the mesh
            MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT = MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT + 1

            -- Writing primitive
            if FD_P == nil then FD_P = io.open(OBJ_PATH..P_EXT, "w+") end
            FD_P:write(MESHLETS[CUR_MATERIAL].INDICES_DICT[v_key].." ")

        end

        -- Updating meshlet size
        MESHLETS[CUR_MATERIAL].SIZE = updated_meshlet_size

    end

end

-- Handles the change of types
finish_meshlets = function ()

    for m, p in pairs(MESHLETS) do

        if m ~= "" or CUR_MATERIAL ~= "" then

            -- Closing previous material files if open
            if FD_I then FD_I:close() end
            if FD_P then FD_P:close() end
            if FD_M then FD_M:close() end

            -- Getting material extension
            local m_ext = ""
            if MATERIALS[m] then
                m_ext = string.format(".%03d", MATERIALS[m].idx)
            end

            -- Opening files for the new materials
            FD_I = io.open(OBJ_PATH..m_ext..I_EXT, "a")
            FD_P = io.open(OBJ_PATH..m_ext..P_EXT, "a")
            FD_M = io.open(OBJ_PATH..m_ext..M_EXT, "a")

            -- Finishing the files
            FD_I:write("\n")
            FD_P:write("\n")
            FD_M:write(
                p.INDICES_OFFSET.." "..p.INDICES_COUNT.." "..
                p.PRIMITIVES_OFFSET.." "..p.PRIMITIVES_COUNT.."\n")

        end

    end

end

-- Converts .obj to several singular purpose files
convertObj = function ()

    -- Importing .obj & .mtl loader
    local obj_loader = require "lib/obj_loader"
    local mtl_loader = require "lib/mtl_loader"

    if not CONVERT_MATERIALS then

        -- Updating current material
        CUR_MATERIAL = "*"
        -- Storing current material index
        MATERIALS[CUR_MATERIAL] = {idx = MATERIALS_IDX}
        MATERIALS[CUR_MATERIAL].Kd = {
            r = "0.5",
            g = "0.5",
            b = "0.5"
        }

        -- Getting current material's properties
        local m = MATERIALS[CUR_MATERIAL]

        -- Opening files for the new materials
        FD_I = io.open(OBJ_PATH..string.format(".%03d", m.idx)..I_EXT, "a")
        FD_P = io.open(OBJ_PATH..string.format(".%03d", m.idx)..P_EXT, "a")
        FD_M = io.open(OBJ_PATH..string.format(".%03d", m.idx)..M_EXT, "a")

        -- Starting Meshlet information for current material
        MESHLETS[CUR_MATERIAL] = {}
        MESHLETS[CUR_MATERIAL].SIZE = MESHLET_SIZE * FLOAT_SIZE
        MESHLETS[CUR_MATERIAL].INDICES_DICT = {}
        MESHLETS[CUR_MATERIAL].INDICES_OFFSET = 0
        MESHLETS[CUR_MATERIAL].INDICES_COUNT = 0
        MESHLETS[CUR_MATERIAL].PRIMITIVES_OFFSET = 0
        MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT = 0

        -- Writing material to file
        FD_MT = io.open(OBJ_PATH..MT_EXT, "w+")
        FD_MT:write(string.format("%03d", m.idx).." " ..CUR_MATERIAL.." "..m.Kd.r.." "..m.Kd.g.." "..m.Kd.b)
        FD_MT:write("\n")

    end

    for parsed_line in obj_loader.load(OBJ_PATH, OBJ_TYPES) do

        local type = parsed_line.type

        if type == "v" then

            -- Setting the size the geometry takes
            if GEOMETRY_SIZE == 0 then GEOMETRY_SIZE = 4 end
            -- Checking if file is open
            if FD_V == nil then FD_V = io.open(OBJ_PATH..V_EXT, "w+") end
            -- Creating string
            local v_str = parsed_line['x'].." "..parsed_line['y'].." "..parsed_line['z'].." "..parsed_line['w']
            -- Writing string to file
            FD_V:write(v_str, '\n')

        elseif type == "vt" and CONVERT_MATERIALS then

            -- Setting the size the texture coordinates take
            if TEXCOORDS_SIZE == 0 then TEXCOORDS_SIZE = 4 end
            -- Checking if file is open
            if FD_VT == nil then FD_VT = io.open(OBJ_PATH..VT_EXT, "w+") end
            -- Creating string
            local vt_str = parsed_line['u'].." "..parsed_line['v'].." "..parsed_line['w']
            -- Writing string to file
            FD_VT:write(vt_str, '\n')

        elseif type == "vn" and CONVERT_NORMALS then

            -- Setting the size the geometry takes
            if NORMALS_SIZE == 0 then NORMALS_SIZE = 3 end
            -- Checking if file is open
            if FD_VN == nil then FD_VN = io.open(OBJ_PATH..VN_EXT, "w+") end
            -- Creating string
            local vn_str = parsed_line['x'].." "..parsed_line['y'].." "..parsed_line['z']
            -- Writing string to file
            FD_VN:write(vn_str, '\n')

        elseif type == "f" then

            -- Processing each triangle separately
            for i=1, #(parsed_line.f)-2 do

                -- Getting 3 vertices that compose the primitive
                local v1, v2, v3 = parsed_line.f[1], parsed_line.f[i+1], parsed_line.f[i+2]
                -- Writing primitive
                write_primitive({v1, v2, v3})

            end

        elseif type == "mtllib" and CONVERT_MATERIALS then

            -- Processing .mtl file
            for mtl_line in mtl_loader.load(parsed_line.file, MTL_TYPES) do

                if mtl_line.type == "newmtl" then

                    -- Updating current material
                    CUR_MATERIAL = mtl_line.m
                    -- Storing current material index
                    MATERIALS[CUR_MATERIAL] = {idx = MATERIALS_IDX}
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

        elseif type == "usemtl" and CONVERT_MATERIALS then

            -- Closing previous material files if open
            if FD_I then FD_I:close() end
            if FD_P then FD_P:close() end
            if FD_M then FD_M:close() end

            -- Storing current material
            CUR_MATERIAL = parsed_line.m

            -- Getting current material's properties
            local m = MATERIALS[CUR_MATERIAL]

            -- Opening files for the new materials
            FD_I = io.open(OBJ_PATH..string.format(".%03d", m.idx)..I_EXT, "a")
            FD_P = io.open(OBJ_PATH..string.format(".%03d", m.idx)..P_EXT, "a")
            FD_M = io.open(OBJ_PATH..string.format(".%03d", m.idx)..M_EXT, "a")

            -- Writing texture to .materials
            if not MESHLETS[CUR_MATERIAL] then

                -- Starting Meshlet information for current material
                MESHLETS[CUR_MATERIAL] = {}
                MESHLETS[CUR_MATERIAL].SIZE = MESHLET_SIZE * FLOAT_SIZE
                MESHLETS[CUR_MATERIAL].INDICES_DICT = {}
                MESHLETS[CUR_MATERIAL].INDICES_OFFSET = 0
                MESHLETS[CUR_MATERIAL].INDICES_COUNT = 0
                MESHLETS[CUR_MATERIAL].PRIMITIVES_OFFSET = 0
                MESHLETS[CUR_MATERIAL].PRIMITIVES_COUNT = 0

                -- Writing material to file
                FD_MT:write(string.format("%03d", m.idx).." " ..CUR_MATERIAL.." "..m.Kd.r.." "..m.Kd.g.." "..m.Kd.b)
                if m.map_Kd ~= nil then
                    FD_MT:write(" "..m.map_Kd)
                end
                FD_MT:write("\n")

            end
        end

    end

    finish_meshlets()

    if FD_V ~= nil then FD_V:close() end
    if FD_VT ~= nil then FD_VT:close() end
    if FD_VN ~= nil then FD_VN:close() end
    if FD_I ~= nil then FD_I:close() end
    if FD_P ~= nil then FD_P:close() end
    if FD_M ~= nil then FD_M:close() end
    if FD_MT ~= nil then FD_MT:close() end

end

-- Prints the table that represents de .obj
printObj = function ()

    -- Checking if file path was given
    if not OBJ_PATH then print("No Wavefront (.obj) provided.") end

    -- Loading Obj
    local obj_loader = require "lib/loader"
    local inspect = require "lib/inspect"

    for parsed_line in obj_loader.load(OBJ_PATH, OBJ_TYPES) do
        print(inspect(parsed_line))
    end

end

-- Parses the program arguments
--- FORMAT: lua obj_converter.lua [FLAGS] file.obj
--- FLAGS:
----- [-mv #n] Sets #n as the max number of vertices that a meshlet should have
----- [-mp #n] Sets #n as the max number of primitives that a meshlet should have
----- [-nn] Makes the conversion ignore the normals
----- [-nm] Makes the conversion ignore the materials
parseArguments = function (arg)

    for i=1, #(arg) - 1 do

        if arg[i] == "-mv" then

            assert (tonumber(arg[i+1]), "Flag -mv must be followed by a number.")
            MAX_MESHLET_VERTICES = tonumber(arg[i+1])
            i = i + 1

        elseif arg[i] == "-mp" then

            assert (tonumber(arg[i+1]), "Flag -mp must be followed by a number.")
            MAX_MESHLET_PRIMITIVES = tonumber(arg[i+1])
            i = i + 1

        elseif arg[i] == "-nn" then

            CONVERT_NORMALS = false

        elseif arg[i] == "-nm" then

            CONVERT_MATERIALS = false

        end

    end

    OBJ_PATH = arg[#arg]

end

-- Parsing arguments
parseArguments(arg)

-- Converting file
convertObj()
