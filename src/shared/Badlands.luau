-- The Badlands (QM, Oct 5): the Nether-style biome between the Ocean and the
-- Godlands. Red sand, red stone a stud up and glowing lava, laid out by QM's
-- MapMaker "Hot" biome (tools/badlands.py, Shared/BadlandsMap). Its walls angle in
-- and out: the course pinches to narrow funnels, then opens into wide chambers
-- where lava geysers on the walls spray across (Client/BadlandsStream).
-- Each client builds it near the camera.
--
--   Badlands.start                -- z of its line (nil if there's no Badlands biome)
--   Badlands.finish               -- z of its far end
--   Badlands.contains(z)          -- whether z is in it
--   Badlands.edgesAt(z)           -- left and right wall x there (nil outside it)
--   Badlands.glyphAt(x, z)        -- "." sand, "#" stone, "~" lava, nil outside it
--   Badlands.heightAt(x, z)       -- the floor's top there
--   Badlands.geysers              -- { { cframe, along } }: each vent, +x into the corridor
--   Badlands.nests                -- { Vector3 } nest spots

local Config = require(script.Parent.Config)
local Map = require(script.Parent.BadlandsMap)

local Badlands = {
	map = Map,
	tile = Map.Tile,
	halfWidth = Map.HalfWidth,
	STONE_UP = 1,
	LAVA_TOP = 0.05, -- lava sits just over the sand, like the Godlands'
	geysers = {},
	nests = {},
}

do
	local edge = 0
	for _, biome in Config.Biomes do
		if biome.Name == "Badlands" then
			Badlands.start = edge
			Badlands.finish = edge - Map.Length
		end
		edge -= biome.Length
	end
end

if Badlands.start then
	for _, g in Map.Geysers do
		table.insert(Badlands.geysers, {
			along = g[1],
			cframe = CFrame.new(g[2], 0, Badlands.start - g[1]) * CFrame.Angles(0, math.rad(g[3]), 0),
		})
	end
	for _, n in Map.Nests do
		table.insert(Badlands.nests, Vector3.new(n[2], 0, Badlands.start - n[1]))
	end
end

function Badlands.contains(z)
	return Badlands.start ~= nil and z < Badlands.start and z >= Badlands.finish
end

-- The walls' x at z: straight lines between Map.Walls points.
function Badlands.edgesAt(z)
	if not Badlands.contains(z) then
		return nil
	end
	local along = Badlands.start - z
	local walls = Map.Walls
	for i = 2, #walls do
		local a, b = walls[i - 1], walls[i]
		if along <= b[1] then
			local t = (along - a[1]) / math.max(b[1] - a[1], 0.001)
			return a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t
		end
	end
	local last = walls[#walls]
	return last[2], last[3]
end

function Badlands.glyphAt(x, z)
	if not Badlands.contains(z) then
		return nil
	end
	local row = Map.Grid[math.floor((Badlands.start - z) / Map.Tile) + 1]
	local i = math.floor((x + Map.HalfWidth) / Map.Tile) + 1
	return if row and i >= 1 and i <= #row then string.sub(row, i, i) else "."
end

function Badlands.heightAt(x, z)
	local g = Badlands.glyphAt(x, z)
	return if g == "#" then Badlands.STONE_UP elseif g == "~" then Badlands.LAVA_TOP else 0
end

return Badlands
