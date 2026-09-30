-- Floor height under a point. Most of the floor's top is at y = 0; raised
-- patches (the desert's sandstone) are parts in World.Ground whose tops stand
-- higher. They're laid out on an 8-stud grid (tools/desert_ground.py), so the
-- height is looked up per 8-stud cell.

local CELL = 8

local Ground = {}

local heights -- [cell key] = top y, only for raised cells

local function key(i, j)
	return (i + 4096) * 8192 + (j + 4096)
end

local function load()
	heights = {}
	for _, part in workspace:WaitForChild("World"):WaitForChild("Ground"):GetChildren() do
		local top = part.Position.Y + part.Size.Y / 2
		if part:IsA("BasePart") and top > 0.01 then
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
