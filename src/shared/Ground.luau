-- Floor height under a point. Most of the floor's top is at y = 0; patches
-- in World.Ground can stand higher (the desert's sandstone) or sit lower (the
-- meadow's dirt). They're laid out on the 4-stud checker (8-stud cells in most
-- biomes, tools/desert_ground.py; single tiles in the Godlands, Server/GodlandsGround),
-- so the height is looked up per 4-stud cell.

local CELL = 4

local Ground = {}

local heights -- [cell key] = top y, only for cells off y = 0

local function key(i, j)
	return (i + 16384) * 32768 + (j + 16384)
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
	if not heights then
		load()
	end
	return heights[key(math.floor(x / CELL), math.floor(z / CELL))] or 0
end

return Ground
