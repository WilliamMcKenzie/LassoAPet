-- Floor height under a point. Most of the floor's top is at y = 0; patches
-- in World.Ground can stand higher (the desert's sandstone) or sit lower (the
-- meadow's dirt). They're laid out on an 8-stud grid (tools/desert_ground.py,
-- tools/meadow_ground.py), so the height is looked up per 8-stud cell.

local Config = require(script.Parent.Config)

local CELL = 8
local endless = Config.Endless -- past its cut, the floor's the stretch before it, again and again (Client/Endless)

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
	if not heights then
		load()
	end
	if endless and z < endless.Cut then
		z = endless.Cut + (z - endless.Cut) % endless.Length
	end
	return heights[key(math.floor(x / CELL), math.floor(z / CELL))] or 0
end

-- The water under a point (QM, Oct 14: things sink a bit in it, Client/WaterSink): "DeepWater",
-- "Water" (a Water part or any with the flowing water tile, a Texture named Water), or nil.
local waters -- [cell key] = its kind
function Ground.waterAt(x, z)
	if not waters then
		waters = {}
		for _, part in workspace:WaitForChild("World"):WaitForChild("Ground"):GetChildren() do
			local kind = if part.Name == "DeepWater" then "DeepWater"
				elseif part.Name == "Water" or part:FindFirstChild("Water") then "Water"
				else nil
			if kind and part:IsA("BasePart") then
				local lo = part.Position - part.Size / 2
				for px = lo.X + CELL / 2, lo.X + part.Size.X, CELL do
					for pz = lo.Z + CELL / 2, lo.Z + part.Size.Z, CELL do
						waters[key(math.floor(px / CELL), math.floor(pz / CELL))] = kind
					end
				end
			end
		end
	end
	return waters[key(math.floor(x / CELL), math.floor(z / CELL))]
end

return Ground
