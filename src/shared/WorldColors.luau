-- Live colour tuning for the ground and walls. In Studio, press Play, select
-- Workspace > World and edit its GroundA / GroundB / WallA / WallB attributes
-- (the first biome and the home base) or DesertGroundA and so on for the other
-- biomes: the map recolours instantly. Copy the values you like into Config.

local Config = require(script.Parent.Config)

local WorldColors = {}

-- Index into Config.Biomes of the biome at z. The course runs toward -z from
-- z = 0; the home base (z > 0) counts as the first biome, past the end as the last.
function WorldColors.biomeAt(z)
	local edge = 0
	for i, biome in Config.Biomes do
		edge -= biome.Length
		if z >= edge then
			return i
		end
	end
	return #Config.Biomes
end

-- The z of biome i's near edge (the line you cross into it).
function WorldColors.biomeStart(i)
	local edge = 0
	for j = 1, i - 1 do
		edge -= Config.Biomes[j].Length
	end
	return edge
end

-- The z of the first gate a player with this pen level can't pass (-inf if none).
function WorldColors.gateZ(level)
	local next = Config.Biomes[(level or 1) + 1]
	return if next then WorldColors.biomeStart((level or 1) + 1) else -math.huge
end

local function prefix(i)
	return if i == 1 then "" else Config.Biomes[i].Name
end
WorldColors.prefix = prefix

local function paint(part, base, checker)
	part.Color = base
	for _, texture in part:GetChildren() do
		if texture.Name == "Checker" then
			texture.Color3 = checker
		end
	end
end

function WorldColors.apply(world)
	local function get(part, key)
		return world:GetAttribute(prefix(WorldColors.biomeAt(part.Position.Z)) .. key)
	end
	for _, part in world.Ground:GetChildren() do
		paint(part, get(part, "GroundA"), get(part, "GroundB"))
	end
	for _, part in world.Walls:GetChildren() do
		if part.Name == "Cap" then
			part.Color = get(part, "GroundB")
		else
			paint(part, get(part, "WallA"), get(part, "WallB"))
		end
	end
end

-- Seeds the attributes (server) and repaints whenever one changes.
function WorldColors.watch(world)
	for i, biome in Config.Biomes do
		local defaults = {
			GroundA = biome.GroundColors[1],
			GroundB = biome.GroundColors[2],
			WallA = biome.WallColors[1],
			WallB = biome.WallColors[2],
		}
		for key, default in defaults do
			key = prefix(i) .. key
			if world:GetAttribute(key) == nil then
				world:SetAttribute(key, default)
			end
			world:GetAttributeChangedSignal(key):Connect(function()
				WorldColors.apply(world)
			end)
		end
	end
	WorldColors.apply(world)
end

return WorldColors
