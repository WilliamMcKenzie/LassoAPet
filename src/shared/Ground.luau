-- Floor height under a point. Most of the floor's top is at y = 0; patches
-- in World.Ground can stand higher (the desert's sandstone) or sit lower (the
-- meadow's dirt). They're laid out on an 8-stud grid (tools/desert_ground.py,
-- tools/meadow_ground.py), so the height is looked up per 8-stud cell.

local CELL = 8

-- Past its line the Godlands is laid out on 4-stud tiles, built by each client
-- as it goes (Shared/Godlands), so its heights come from its track grids instead.
local Godlands = require(script.Parent.Godlands)
-- So is the Badlands (Shared/Badlands): its red stone stands a stud up.
local Badlands = require(script.Parent.Badlands)

local Ground = {}

local heights -- [cell key] = top y, only for cells off y = 0

local function key(i, j)
	return (i + 4096) * 8192 + (j + 4096)
end

local function load()
	heights = {}
	for _, part in workspace:WaitForChild("World"):WaitForChild("Ground"):GetChildren() do
		local top = part.Position.Y + part.Size.Y / 2
		if part:IsA("BasePart") and math.abs(top) > 0.01 then
			local lo = part.Position - part.Size / 2
			for x = lo.X + CELL / 2, lo.X + part.Size.X, CELL do
				for z = lo.Z + CELL / 2, lo.Z + part.Size.Z, CELL do
					heights[key(math.floor(x / CELL), math.floor(z / CELL))] = top
				end
			end
		end
	end
end

function Ground.heightAt(x, z)
	if Godlands.start and z < Godlands.start then
		return Godlands.heightAt(x, z)
	end
	if Badlands.contains(z) then
		return Badlands.heightAt(x, z)
	end
	if not heights then
		load()
	end
	return heights[key(math.floor(x / CELL), math.floor(z / CELL))] or 0
end

return Ground
