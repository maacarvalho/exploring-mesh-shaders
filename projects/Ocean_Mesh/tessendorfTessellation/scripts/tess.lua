gridSize, maxTess, gridSpacing = 255, 64, 20
totalLength, totalTess = gridSize * gridSpacing, gridSize * maxTess

setTess1x = function ()

    setAttr("RENDERER", "CURRENT", "GridSize", 0, {gridSize})
    setAttr("RENDERER", "CURRENT", "GridSpacing", 0, {gridSpacing})
    setAttr("RENDERER", "CURRENT", "MaxTessellationLvl", 0, {maxTess})

end

setTess2x = function ()

    local newGridSize = math.floor(gridSize * 0.5)

    setAttr("RENDERER", "CURRENT", "GridSize", 0, {newGridSize})
    setAttr("RENDERER", "CURRENT", "GridSpacing", 0, {totalLength / newGridSize})
    setAttr("RENDERER", "CURRENT", "MaxTessellationLvl", 0, {totalTess / newGridSize})

end

setTess4x = function ()

    local newGridSize = math.floor(gridSize * 0.25)

    setAttr("RENDERER", "CURRENT", "GridSize", 0, {newGridSize})
    setAttr("RENDERER", "CURRENT", "GridSpacing", 0, {totalLength / newGridSize})
    setAttr("RENDERER", "CURRENT", "MaxTessellationLvl", 0, {totalTess / newGridSize})

end

setTess8x = function ()

    local newGridSize = math.floor(gridSize * 0.125)

    setAttr("RENDERER", "CURRENT", "GridSize", 0, {newGridSize})
    setAttr("RENDERER", "CURRENT", "GridSpacing", 0, {totalLength / newGridSize})
    setAttr("RENDERER", "CURRENT", "MaxTessellationLvl", 0, {totalTess / newGridSize})

end

setTess16x = function ()

    local newGridSize = math.floor(gridSize * 0.0625)

    setAttr("RENDERER", "CURRENT", "GridSize", 0, {newGridSize})
    setAttr("RENDERER", "CURRENT", "GridSpacing", 0, {totalLength / newGridSize})
    setAttr("RENDERER", "CURRENT", "MaxTessellationLvl", 0, {totalTess / newGridSize})

end

setTess32x = function ()

    local newGridSize = math.floor(gridSize * 0.03125)

    setAttr("RENDERER", "CURRENT", "GridSize", 0, {newGridSize})
    setAttr("RENDERER", "CURRENT", "GridSpacing", 0, {totalLength / newGridSize})
    setAttr("RENDERER", "CURRENT", "MaxTessellationLvl", 0, {totalTess / newGridSize})

end
