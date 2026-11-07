-- Floor height under a point, and the water there, from the map's floor (workspace.World.Floor:
-- Server/Map builds it from the map editor's map, one part per run of 4-stud cells). Most of it
-- is at y = 0; tiles can stand higher or sit lower, so the height is looked up per 4-stud cell.
-- (Read off the parts, not Shared/MapData: decoding the whole map is too much for a client.)

local CELL = 4

local Ground = {}

-- (past the Ocean the course is generated, not parts in the Floor: Shared/Endless works it out)
local Endless = require(script.Parent.Endless)
local ENDLESS_FROM = if Endless.On then Endless.START else -math.huge

local heights -- [cell key] = top y, only for cells off y = 0
local waters -- [cell key] = "Water", for the liquid tiles

local function key(i, j)
	return (i + 8192) * 16384 + (j + 8192)
end

local function load()
	heights, waters = {}, {}
	local floor = workspace:WaitForChild("World"):WaitForChild("Floor")
	for _, part in floor:GetDescendants() do
		if part:IsA("BasePart") and part.CanCollide then
			local top = part.Position.Y + part.Size.Y / 2
			local liquid = part:GetAttribute("Liquid") == true
			if math.abs(top) > 0.01 or liquid then
				local lo = part.Position - part.Size / 2
				for x = lo.X + CELL / 2, lo.X + part.Size.X, CELL do
					for z = lo.Z + CELL / 2, lo.Z + part.Size.Z, CELL do
						local k = key(math.floor(x / CELL), math.floor(z / CELL))
						if liquid then
							waters[k] = "Water"
						else
							heights[k] = top
						end
					end
				end
			end
		end
	end
end

function Ground.heightAt(x, z)
	if z < ENDLESS_FROM then
		return Endless.heightAt(x, z)
	end
	if not heights then
		load()
	end
	return heights[key(math.floor(x / CELL), math.floor(z / CELL))] or 0
end

-- The water under a point (QM, Oct 14: things sink a bit in it, Client/WaterSink): "Water" on
-- a liquid tile (the map's water and magma), or nil.
function Ground.waterAt(x, z)
	if z < ENDLESS_FROM then
		return if Endless.liquidAt(x, z) then "Water" else nil
	end
	if not waters then
		load()
	end
	return waters[key(math.floor(x / CELL), math.floor(z / CELL))]
end

return Ground
