-- The Godlands, the last biome: it never ends (QM, Oct 3). Past its line the
-- course is one track after another (Shared/GodlandsTracks, 960 studs each),
-- each picked at random from the four, forever. The picks come from a seed the
-- server sets when it starts (World.GodlandsSeed), so everyone on a server rides
-- the same ground. Client/GodlandsStream builds the tracks near each player.
--
--   Godlands.start                -- z of its line (nil if there's no Godlands biome)
--   Godlands.length               -- studs per track
--   Godlands.segmentAt(z)         -- which track along it z is in (0 = the first), nil before it
--   Godlands.segmentStart(k)      -- z of track k's near end
--   Godlands.track(k)             -- the track laid at k: { Grid, Liquid }
--   Godlands.glyphAt(x, z)        -- "." snow, "#" stone, "~" ice/lava, nil before it
--   Godlands.heightAt(x, z)       -- the floor's top there

local Config = require(script.Parent.Config)
local Tracks = require(script.Parent.GodlandsTracks)

-- The tracks' grids are drawn for a 112-stud course; the course is a funnel (Config)
-- that's CourseMaxHalfWidth wide by here, so they're laid stretched across it:
-- grid x times `widen`, snapped to the 4-stud tiles (Godlands.worldX).
local gridHalf = #Tracks.Grids[1][1] * Tracks.Tile / 2
local Godlands = {
	length = Tracks.Length,
	tile = Tracks.Tile,
	gridHalf = gridHalf,
	halfWidth = math.floor(Config.CourseMaxHalfWidth / Tracks.Tile + 0.5) * Tracks.Tile,
	STONE_UP = 1,
	LIQUID_TOP = 0.05, -- ice and lava sit just over the snow
}

do
	local edge = 0
	for i, biome in Config.Biomes do
		if biome.Name == "Godlands" then
			Godlands.start, Godlands.biome = edge, i
		end
		edge -= biome.Length
	end
end

local picks = {} -- [k] = track
local seed

function Godlands.segmentAt(z)
	if not Godlands.start or z >= Godlands.start then
		return nil
	end
	return math.floor((Godlands.start - z) / Tracks.Length)
end

function Godlands.segmentStart(k)
	return Godlands.start - k * Tracks.Length
end

function Godlands.track(k)
	if not seed then
		local world = workspace:FindFirstChild("World")
		seed = world and world:GetAttribute("GodlandsSeed")
		if not seed then
			return Tracks.Tracks[1] -- not set yet (the world isn't ready)
		end
	end
	local t = picks[k]
	if not t then
		t = Tracks.Tracks[Random.new(seed * 65536 + k):NextInteger(1, #Tracks.Tracks)]
		picks[k] = t
	end
	return t
end

Godlands.widen = Godlands.halfWidth / gridHalf

-- A grid x (-gridHalf..gridHalf) laid across the wider course, on the tile grid.
function Godlands.worldX(x)
	return math.floor(x * Godlands.widen / Tracks.Tile + 0.5) * Tracks.Tile
end

function Godlands.glyphAt(x, z)
	local k = Godlands.segmentAt(z)
	if not k then
		return nil
	end
	local row = Tracks.Grids[Godlands.track(k).Grid][math.floor((Godlands.segmentStart(k) - z) / Tracks.Tile) + 1]
	local i = math.floor((x / Godlands.widen + gridHalf) / Tracks.Tile) + 1
	return if row and i >= 1 and i <= #row then string.sub(row, i, i) else "."
end

function Godlands.heightAt(x, z)
	local g = Godlands.glyphAt(x, z)
	return if g == "#" then Godlands.STONE_UP elseif g == "~" then Godlands.LIQUID_TOP else 0
end

return Godlands
