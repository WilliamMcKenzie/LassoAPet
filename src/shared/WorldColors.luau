-- Live colour tuning for the ground and walls. In Studio, press Play, select
-- Workspace > World and edit its GroundA / GroundB / WallA / WallB attributes
-- (the first biome and the home base) or DesertGroundA and so on for the other
-- biomes (DesertGrassA, DesertStoneA... for their Patches): the map recolours
-- instantly. Copy the values you like into Config.

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

-- Where z is along biome i, 0 at its near edge to 1 at its far one.
function WorldColors.along(i, z)
	return math.clamp((WorldColors.biomeStart(i) - z) / Config.Biomes[i].Length, 0, 1)
end

-- Biome i's Depths stops (Config) either side of z and the fraction to blend
-- between them, or nil if it has none.
function WorldColors.depthAt(i, z)
	local stops = Config.Biomes[i].Depths
	if not stops then
		return nil
	end
	local t = WorldColors.along(i, z)
	for k = 2, #stops do
		if t <= stops[k].At then
			return stops[k - 1], stops[k], (t - stops[k - 1].At) / (stops[k].At - stops[k - 1].At)
		end
	end
	return stops[#stops], stops[#stops], 0
end

local function depthColor(i, z, name, which)
	local a, b, f = WorldColors.depthAt(i, z)
	if a and a[name] and b[name] then
		return a[name][which]:Lerp(b[name][which], f)
	end
	return nil
end

local function paint(part, base, checker)
	part.Color = base
	for _, texture in part:GetChildren() do
		if texture.Name == "Checker" then
			texture.Color3 = checker
		end
	end
end

function WorldColors.apply(world)
	local function get(part, name, which)
		local z = part.Position.Z
		local i = WorldColors.biomeAt(z)
		return depthColor(i, z, name, if which == "A" then 1 else 2)
			or world:GetAttribute(prefix(i) .. name .. which)
	end
	for _, part in world.Ground:GetChildren() do
		-- "Ground" is the biome's base floor; other names are its Patches (Grass, Stone)
		paint(part, get(part, part.Name, "A"), get(part, part.Name, "B"))
	end
	for _, part in world.Walls:GetChildren() do
		if part.Name == "Cap" then
			part.Color = get(part, "Ground", "B")
		else
			paint(part, get(part, "Wall", "A"), get(part, "Wall", "B"))
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
		for name, colors in biome.Patches or {} do
			defaults[name .. "A"], defaults[name .. "B"] = colors[1], colors[2]
		end
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
