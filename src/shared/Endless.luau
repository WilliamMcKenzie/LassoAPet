-- The endless course past the Ocean Trench (QM, Nov 6; Config.Endless): stretches of World 2's
-- Marble Meadow, Crimson Lands and Crystal Cavern, one after another for ever, each picked at
-- random (never the one before again) for a random length. Everything here is worked out from
-- Config.Endless.Seed alone, by hashing, so every client and the server lay out the same course
-- without sending anything; Client/Endless builds the parts near the camera from it.
--
-- How a stretch's terrain is made (4-stud cells, as the map editor's):
--   1. The corridor breathes: its half width is fractal noise along the course, with a narrow
--      gorge now and then, each biome a little wider or narrower (eased over 160 studs).
--   2. Its walls are two tiers each side, as the map's: a ledge and a cliff behind it, their
--      heights stepped noise (each side its own), the cliff's width ragged, so the skyline's jagged.
--   3. The floor is domain-warped fractal noise read through each biome's own rules: the Marble
--      Meadow's ponds, knolls and ruined marble plazas; the Crimson Lands' ridged-noise veins of
--      raised rock, sunken basins and single stones ringed in crimson; the Crystal Cavern's
--      ground to ice to crystal toward its middle line, rock shelves and pools.
--   4. A causeway snakes down each stretch (two sine waves, back to the middle at both ends, so
--      one stretch's meets the next's): a marble road, a stone road, the crystal vein, with
--      plank bridges over the Cavern's pools.
--   5. Props scatter on a jittered grid (an even spread with no rows), thicker in groves (low-
--      frequency noise) and by the walls; the ones in the corridor are obstacles the ride smashes.
--   6. Each stretch has a set piece at its middle: a marble arch, a rune gate, a rock bridge.
--   7. Where two stretches meet, the line between them is ragged (teeth up to Config.Endless.Blend).
--
--   Endless.On, Endless.START (the Ocean's far end), Endless.CELL, Endless.CHUNK
--   Endless.segmentAt(z) -> { index, biome, template, from, to, length, ... } (nil before START)
--   Endless.templateAt(z) -> the Config.Endless.Biomes entry at z, or nil
--   Endless.halfWidth(z), Endless.heightAt(x, z), Endless.liquidAt(x, z)
--   Endless.rows(j0, j1) -> the floor and walls of cell rows j0..j1 as merged rectangles
--   Endless.props(z0, z1), Endless.landmarks(z0, z1)

local Config = require(script.Parent.Config)

local E = Config.Endless
local Endless = {}
Endless.On = E ~= nil
if not E then
	return Endless
end

local CELL = 4
Endless.CELL = CELL
Endless.CHUNK = 64 -- studs of course per built chunk (Client/Endless)
local START = -Config.CourseLength -- the Ocean's far end (maps/world.map's last row)
Endless.START = START
local OCEAN_HALF = Config.CourseProfile and Config.CourseProfile[#Config.CourseProfile][2] or 160

-- ---- hashing and noise (integer maths in 32 bits, so it's the same on every machine) ----

local TWO32 = 4294967296
local bxor, rshift, band = bit32.bxor, bit32.rshift, bit32.band
local function mul(a, b) -- a * b mod 2^32, without going past a double's 53 bits
	return ((rshift(a, 16) * b % 65536) * 65536 + band(a, 65535) * b) % TWO32
end
local function mix(h)
	h = bxor(h, rshift(h, 15))
	h = mul(h, 0x2C1B3C6D)
	h = bxor(h, rshift(h, 12))
	h = mul(h, 0x297A2D39)
	return bxor(h, rshift(h, 15))
end
local SEED = E.Seed % TWO32
-- [0, 1) from integers a, b and a salt c
local function hash(a, b, c)
	local h = mix(bxor(a % TWO32, SEED))
	h = mix(bxor(h, b % TWO32))
	return mix(bxor(h, c % TWO32)) / TWO32
end
Endless.hash = hash

local function fade(t)
	return t * t * (3 - 2 * t)
end
local function value2(x, z, salt)
	local xi, zi = math.floor(x), math.floor(z)
	local fx, fz = fade(x - xi), fade(z - zi)
	local a, b = hash(xi, zi, salt), hash(xi + 1, zi, salt)
	local c, d = hash(xi, zi + 1, salt), hash(xi + 1, zi + 1, salt)
	local top = a + (b - a) * fx
	return top + (c + (d - c) * fx - top) * fz
end
local function value1(t, salt)
	local ti = math.floor(t)
	local a, b = hash(ti, 0, salt), hash(ti + 1, 0, salt)
	return a + (b - a) * fade(t - ti)
end
-- fractal: octaves of value noise, each twice as fine and half as strong, back to [0, 1]
local function fbm(x, z, salt, octaves)
	local sum, amp, norm = 0, 1, 0
	for o = 1, octaves do
		sum += value2(x, z, salt + o * 101) * amp
		norm += amp
		amp *= 0.5
		x *= 2.03
		z *= 2.03
	end
	return sum / norm
end
local function fbm1(t, salt, octaves)
	local sum, amp, norm = 0, 1, 0
	for o = 1, octaves do
		sum += value1(t, salt + o * 101) * amp
		norm += amp
		amp *= 0.5
		t *= 2.03
	end
	return sum / norm
end
local function smooth(a, b, v)
	local t = math.clamp((v - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

-- ---- the stretches ------------------------------------------------------------------------

-- How each biome's terrain differs (by Config.Endless.Biomes Name)
local STYLE = {
	MarbleMeadow = { widthBias = 18, ledge = { 30, 40, 60 }, cliff = { 90, 120, 160 }, causeway = 10 },
	CrimsonLands = { widthBias = 0, ledge = { 30, 40, 60 }, cliff = { 80, 120, 220 }, causeway = 8 },
	CrystalCavern = { widthBias = -22, ledge = { 40, 60, 90 }, cliff = { 120, 220, 320 }, causeway = 12 },
}
Endless.STYLE = STYLE

local segments = {}
local function segment(s)
	while #segments < s do
		local n = #segments + 1
		local prev = segments[n - 1]
		local count = #E.Biomes
		local pick
		if prev and count > 1 then
			pick = 1 + math.floor(hash(n, 1, 7) * (count - 1))
			if pick >= prev.biome then
				pick += 1 -- (never the same biome twice running)
			end
		else
			pick = 1 + math.floor(hash(n, 1, 7) * count)
		end
		local steps = math.floor(E.MaxLength / 16) - math.ceil(E.MinLength / 16)
		local length = 16 * (math.ceil(E.MinLength / 16) + math.floor(hash(n, 2, 7) * (steps + 1)))
		local from = if prev then prev.to else START
		local template = E.Biomes[pick]
		segments[n] = {
			index = n,
			biome = pick,
			template = template,
			style = STYLE[template.Name] or STYLE.MarbleMeadow,
			from = from, -- its near edge (toward home)
			to = from - length, -- its far edge
			length = length,
			salt = n * 1013,
			phase = hash(n, 3, 7) * 2 * math.pi,
			phase2 = hash(n, 4, 7) * 2 * math.pi,
			wave = 380 + hash(n, 5, 7) * 340, -- studs per sway of the causeway
			wave2 = 150 + hash(n, 6, 7) * 110,
			sway = 0.25 + hash(n, 8, 7) * 0.3, -- how far it swings, as a share of the half width
		}
	end
	return segments[s]
end
Endless.segment = segment

-- The stretch at z (from >= z > to), or nil before the endless course starts.
function Endless.segmentAt(z)
	if z > START then
		return nil
	end
	local n = #segments
	if n == 0 or segments[n].to >= z then
		repeat
			n += 1
		until segment(n).to < z
	end
	local lo, hi = 1, n
	while lo < hi do
		local mid = (lo + hi) // 2
		if segments[mid].to < z then
			hi = mid
		else
			lo = mid + 1
		end
	end
	return segments[lo]
end

function Endless.templateAt(z)
	local seg = Endless.segmentAt(z)
	return seg and seg.template
end

-- ---- the corridor's width -----------------------------------------------------------------

local widthCache, widthCount = {}, 0
-- The half width of cell row j (z from 4j to 4j + 4), whole cells.
local function rowHalf(j)
	local cached = widthCache[j]
	if cached then
		return cached
	end
	local z = j * CELL + CELL / 2
	local seg = Endless.segmentAt(z)
	local w = 168 + 120 * (fbm1(z / 640, 11, 3) - 0.5)
	local g = value1(z / 1500, 13) -- a gorge now and then
	if g > 0.7 then
		w -= (g - 0.7) / 0.3 * 64
	end
	-- each biome's own bias, eased in from the one before over its first 160 studs
	local bias = seg.style.widthBias
	local prev = seg.index > 1 and segment(seg.index - 1)
	if prev then
		bias = prev.style.widthBias + (bias - prev.style.widthBias) * smooth(0, 160, seg.from - z)
	end
	w = math.clamp(w + bias, 112, 236)
	w += (OCEAN_HALF - w) * (1 - smooth(0, 240, START - z)) -- (out of the Ocean's width)
	w = math.floor(w / CELL + 0.5) * CELL
	if widthCount > 8192 then
		widthCache, widthCount = {}, 0
	end
	widthCache[j], widthCount = w, widthCount + 1
	return w
end
function Endless.halfWidth(z)
	return rowHalf(math.floor(math.min(z, START - 0.01) / CELL))
end

-- The causeway's middle at z in stretch seg (back to x = 0 at both its ends), and its half width.
local function causeway(seg, z, w)
	local along = (seg.from - z) / seg.length
	local envelope = math.min(1, along * 6, (1 - along) * 6)
	local d = seg.from - z
	local x = math.sin(d / seg.wave * 2 * math.pi + seg.phase) * 0.8 + math.sin(d / seg.wave2 * 2 * math.pi + seg.phase2) * 0.2
	return x * seg.sway * w * envelope, seg.style.causeway
end

-- ---- the walls: a ledge and a cliff each side ----------------------------------------------

local function level(list, v)
	return list[math.clamp(1 + math.floor(v * #list), 1, #list)]
end
-- Row j's walls on `side` (1 east, -1 west): the ledge's width and top, the cliff's width and top.
local function wallsOf(j, side, seg)
	local z = j * CELL + CELL / 2
	local salt = if side > 0 then 300 else 400
	local ledgeW = 24 + CELL * math.floor(value1(z / 300, salt + 1) * 5) -- 24..40
	local ledgeTop = level(seg.style.ledge, value1(z / 180, salt + 2))
	local cliffW = 64 + CELL * math.floor(fbm1(z / 220, salt + 3, 2) * 24) -- 64..160, ragged
	local cliffTop = level(seg.style.cliff, fbm1(z / 260, salt + 4, 2) * 1.35 - 0.12)
	return ledgeW, ledgeTop, cliffW, math.max(cliffTop, ledgeTop + 20)
end
Endless.wallsOf = function(z, side)
	local j = math.floor(z / CELL)
	return wallsOf(j, side, Endless.segmentAt(j * CELL + CELL / 2))
end

-- ---- the floor ------------------------------------------------------------------------------

-- Tiles: { key (ColorKey), top (studs), liquid }
local TILES = {}
local TILE_ID = {}
local function tile(key, top, liquid)
	local id = key .. "|" .. top
	if not TILE_ID[id] then
		table.insert(TILES, { key = key, top = top, liquid = liquid == true })
		TILE_ID[id] = #TILES
	end
	return TILE_ID[id]
end
Endless.TILES = TILES

local T = {
	MarbleGrass = tile("MarbleGrass", 0),
	MarbleKnoll = tile("MarbleGrass", 0.5),
	MarbleDark = tile("MarbleDarkGrass", 0),
	MarbleDirt = tile("MarbleDirt", -0.5),
	MarbleStone = tile("MarbleStone", 0.5),
	MarbleWater = tile("MarbleWater", -1, true),
	CrimsonGround = tile("CrimsonGround", 0),
	CrimsonPatch = tile("CrimsonPatch", 0),
	CrimsonShoulder = tile("CrimsonPatch", 0.5),
	CrimsonCrest = tile("CrimsonStone", 1),
	CrimsonStone = tile("CrimsonStone", 0),
	CrimsonRoad = tile("CrimsonStone", 0.5),
	CrimsonBasin = tile("CrimsonDark", -0.5),
	CavernGround = tile("CavernGround", 0),
	CavernIce = tile("CavernIce", 0),
	CavernCrystal = tile("CavernCrystal", 0),
	CavernShelf = tile("CavernRock", 0.5),
	CavernRock = tile("CavernRock", 1),
	CavernWater = tile("CavernWater", -1, true),
	CavernPlank = tile("CavernPlank", 0),
}

-- (thresholds on the fractal noise, which bunches round 0.5: measured over 400 chunks, ponds are
-- about 15% of a Marble Meadow or Crystal Cavern floor, knolls and shelves 15%, the Crimson
-- Lands' basins 15% and its veins 25%)
local LOW, HIGH, HIGHER = 0.37, 0.63, 0.68

-- Where stretch n meets stretch n + 1, the line between them is ragged: this far past its
-- edge at x (within Config.Endless.Blend), so one's tiles reach into the other's in teeth.
local function edgeOffset(n, x)
	return (value1(x / 24, 990 + n) - 0.5) * E.Blend
end
-- the stretch whose rules make cell (i, j): its own, or near an edge the next or last one's
local function cellSegment(i, j, z)
	local seg = Endless.segmentAt(z)
	local half = E.Blend / 2
	local x = i * CELL + CELL / 2
	if z - seg.to < half then
		if z < seg.to + edgeOffset(seg.index, x) then
			return segment(seg.index + 1)
		end
	elseif seg.from - z < half and seg.index > 1 then
		if z >= seg.from + edgeOffset(seg.index - 1, x) then
			return segment(seg.index - 1)
		end
	end
	return seg
end

local function stoneAt(i, j, salt)
	return hash(i, j, 41 + salt) < 0.008
end

-- The tile of floor cell (i, j) inside the corridor (half width w).
local function floorTile(i, j, w)
	local x, z = i * CELL + CELL / 2, j * CELL + CELL / 2
	local seg = cellSegment(i, j, z)
	local salt = seg.salt
	local name = seg.template.Name
	local xc, cw = causeway(seg, z, w)
	local onRoad = math.abs(x - xc) < cw
	local wx = x + 80 * (value2(x / 90, z / 90, salt + 1) - 0.5)
	local wz = z + 80 * (value2(x / 90 + 17.3, z / 90 + 4.1, salt + 2) - 0.5)
	local h = fbm(wx / 110, wz / 110, salt + 3, 3)
	if name == "CrimsonLands" then
		if onRoad then
			return T.CrimsonRoad
		end
		local r = 1 - math.abs(2 * fbm(wx / 150, wz / 150, salt + 4, 2) - 1) -- ridged: 1 along the veins
		if r > 0.95 then
			return T.CrimsonCrest
		elseif r > 0.9 then
			return T.CrimsonShoulder
		elseif h < LOW + 0.02 then
			return T.CrimsonBasin
		elseif stoneAt(i, j, salt) then
			return T.CrimsonStone
		elseif stoneAt(i + 1, j, salt) or stoneAt(i - 1, j, salt) or stoneAt(i, j + 1, salt) or stoneAt(i, j - 1, salt) then
			return T.CrimsonPatch -- (crimson round every stone, as World 2's)
		end
		return T.CrimsonGround
	elseif name == "CrystalCavern" then
		if h < LOW then
			return if onRoad then T.CavernPlank else T.CavernWater
		elseif h > HIGHER then
			return T.CavernRock
		elseif h > HIGH then
			return T.CavernShelf
		end
		local band = (math.abs(x - xc) + 36 * (value2(x / 30, z / 30, salt + 5) - 0.5)) / w
		return if band < 0.16 then T.CavernCrystal elseif band < 0.45 then T.CavernIce else T.CavernGround
	end
	-- the Marble Meadow
	if onRoad then
		return T.MarbleStone
	end
	-- ruined plazas: some 72-stud squares hold a marble floor, worn through in places
	local mi, mj = math.floor(x / 72), math.floor(z / 72)
	if math.abs(x) < w - 12 and hash(mi, mj, salt + 31) < 0.3 then
		local px, pz = math.floor((x - mi * 72) / CELL), math.floor((z - mj * 72) / CELL) -- 0..17
		local a, b = 1 + math.floor(hash(mi, mj, salt + 32) * 4), 1 + math.floor(hash(mi, mj, salt + 33) * 4)
		local c, d = 1 + math.floor(hash(mi, mj, salt + 34) * 4), 1 + math.floor(hash(mi, mj, salt + 35) * 4)
		if px >= a and px <= 17 - b and pz >= c and pz <= 17 - d then
			return if value2(x / 12, z / 12, salt + 36) > 0.34 then T.MarbleStone else T.MarbleDirt
		end
	end
	if h < LOW then
		return T.MarbleWater
	elseif h < LOW + 0.02 then
		return T.MarbleDirt
	elseif h > HIGH then
		return T.MarbleKnoll
	elseif value2(x / 40, z / 40, salt + 6) > 0.68 then
		return T.MarbleDark
	end
	return T.MarbleGrass
end

local cellCache, cellRows = {}, 0
local function cellAt(i, j)
	local row = cellCache[j]
	if not row then
		if cellRows > 1024 then
			cellCache, cellRows = {}, 0
		end
		row = {}
		cellCache[j], cellRows = row, cellRows + 1
	end
	local id = row[i]
	if id == nil then
		local w = rowHalf(j)
		local x = i * CELL + CELL / 2
		id = if math.abs(x) < w then floorTile(i, j, w) else false
		row[i] = id
	end
	return id
end

-- The floor's height at (x, z) as Shared/Ground gives it: a tile's top, 0 on liquid (it sinks
-- you instead: Ground.waterAt) and outside the corridor.
function Endless.heightAt(x, z)
	local id = cellAt(math.floor(x / CELL), math.floor(z / CELL))
	local t = id and TILES[id]
	return if t and not t.liquid then t.top else 0
end
function Endless.liquidAt(x, z)
	local id = cellAt(math.floor(x / CELL), math.floor(z / CELL))
	return id and TILES[id].liquid or false
end
-- Whether (x, z) is on its stretch's causeway (props keep off it).
function Endless.onCauseway(x, z, pad)
	local seg = Endless.segmentAt(z)
	local w = Endless.halfWidth(z)
	local xc, cw = causeway(seg, z, w)
	return math.abs(x - xc) < cw + (pad or 0)
end

-- Cell rows j0..j1 (j0 <= j1) as rectangles of one tile each, runs across a row merged with the
-- same run in the rows after: { x0, x1, z0, z1, tile } for floor (tile: a TILES index) and
-- { x0, x1, z0, z1, key, top, cap, side, ledge } for walls (z0 < z1).
-- onRow (optional) is called after each row (Client/Endless yields there to spread the work).
function Endless.rows(j0, j1, onRow)
	local floors, walls = {}, {}
	local openF, openW = {}, {}
	local function close(open, out, keep)
		for k, rect in open do
			if not keep[k] then
				table.insert(out, rect)
				open[k] = nil
			end
		end
	end
	for j = j0, j1 do
		local z0, z1 = j * CELL, j * CELL + CELL
		local w = rowHalf(j)
		local seg = Endless.segmentAt(z0 + CELL / 2)
		local seenF, seenW = {}, {}
		-- floor runs
		local i0 = -(w // CELL)
		local runStart, runId = i0, cellAt(i0, j)
		for i = i0 + 1, w // CELL do
			local id = if i < w // CELL then cellAt(i, j) else nil
			if id ~= runId then
				local k = runStart .. ":" .. i .. ":" .. runId
				local rect = openF[k]
				if rect then
					rect[4] = z1
				else
					rect = { runStart * CELL, i * CELL, z0, z1, runId }
					openF[k] = rect
				end
				seenF[k] = true
				runStart, runId = i, id
			end
		end
		-- walls: east and west, ledge then cliff
		local name = seg.template.Name
		local prefix = if name == "CrimsonLands" then "Crimson" elseif name == "CrystalCavern" then "Cavern" else "Marble"
		for _, side in { 1, -1 } do
			local ledgeW, ledgeTop, cliffW, cliffTop = wallsOf(j, side, seg)
			for part, span in { { w, w + ledgeW, ledgeTop }, { w + ledgeW, w + ledgeW + cliffW, cliffTop } } do
				local a, b = span[1] * side, span[2] * side
				local x0, x1 = math.min(a, b), math.max(a, b)
				local k = x0 .. ":" .. x1 .. ":" .. span[3] .. ":" .. prefix
				local rect = openW[k]
				if rect then
					rect[4] = z1
				else
					rect = { x0, x1, z0, z1, prefix .. "Wall", span[3], prefix .. "Cap", side, part == 1 }
					openW[k] = rect
				end
				seenW[k] = true
			end
		end
		close(openF, floors, seenF)
		close(openW, walls, seenW)
		if onRow then
			onRow()
		end
	end
	close(openF, floors, {})
	close(openW, walls, {})
	return floors, walls
end

-- ---- props ------------------------------------------------------------------------------------

-- Each biome's props: { kind, weight, tier (Config.ObstacleTiers' scale: 1 small, 3 big), scale range }
local PROPS = {
	MarbleMeadow = {
		inside = { { "Column", 3, 3, 0.9, 1.3 }, { "BrokenColumn", 4, 3, 0.8, 1.2 }, { "Drum", 3, 2, 0.8, 1.2 }, { "MarbleBlock", 2, 2, 0.8, 1.3 }, { "Bush", 5, 1, 0.8, 1.4 } },
		ledge = { { "Column", 3, 3, 1.1, 1.6 }, { "Bush", 4, 1, 1, 1.6 } },
	},
	CrimsonLands = {
		inside = { { "GiantShroom", 2, 3, 1, 1.3 }, { "Shroom", 4, 2, 0.8, 1.2 }, { "SmallShroom", 4, 1, 0.8, 1.2 }, { "Runestone", 3, 3, 0.9, 1.3 }, { "ShortRunestone", 3, 2, 0.8, 1.2 }, { "Tuft", 5, 1, 0.8, 1.4 } },
		ledge = { { "GiantShroom", 3, 3, 1.2, 1.7 }, { "Runestone", 2, 3, 1.2, 1.6 } },
	},
	CrystalCavern = {
		inside = { { "Crystals", 4, 3, 0.9, 1.4 }, { "PinkCrystals", 2, 3, 0.9, 1.3 }, { "SmallCrystals", 4, 1, 0.8, 1.3 }, { "Stalagmite", 3, 2, 0.8, 1.4 }, { "CavernShroom", 2, 3, 1, 1.4 } },
		ledge = { { "Crystals", 4, 3, 1.3, 2 }, { "Stalagmite", 3, 2, 1.3, 2 } },
	},
}
local GRID = 40 -- studs: one prop at most per square, jittered inside it

local function pick(list, v)
	local total = 0
	for _, p in list do
		total += p[2]
	end
	v *= total
	for _, p in list do
		v -= p[2]
		if v < 0 then
			return p
		end
	end
	return list[#list]
end

-- The props standing between z0 and z1 (z0 > z1, within the endless course): { kind, x, z, y,
-- yaw (radians), scale, tier, obstacle, seed }. Obstacles stand in the corridor; the rest on the ledges.
function Endless.props(z0, z1)
	local out = {}
	for gj = math.floor(z1 / GRID), math.floor(z0 / GRID) do
		for gi = -12, 11 do
			local x = gi * GRID + 4 + hash(gi, gj, 62) * (GRID - 8)
			local z = gj * GRID + 4 + hash(gi, gj, 63) * (GRID - 8)
			if z > z0 or z <= z1 or z > START - 24 then
				continue
			end
			local seg = Endless.segmentAt(z)
			local set = PROPS[seg.template.Name] or PROPS.MarbleMeadow
			local w = Endless.halfWidth(z)
			local ax = math.abs(x)
			local side = if x >= 0 then 1 else -1
			local grove = value2(x / 220, z / 220, seg.salt + 64) -- (props gather in groves)
			local roll = hash(gi, gj, 61)
			local list, y, obstacle
			if ax < w - 10 then
				local nearWall = 1 - smooth(20, 60, w - ax)
				if roll > (0.1 + 0.3 * grove + 0.35 * nearWall) or Endless.onCauseway(x, z, 6) or Endless.liquidAt(x, z) then
					continue
				end
				list, y, obstacle = set.inside, Endless.heightAt(x, z), true
			else
				local ledgeW, ledgeTop = Endless.wallsOf(z, side)
				if ax < w + 6 or ax > w + ledgeW - 6 or roll > 0.25 + 0.4 * grove then
					continue
				end
				list, y, obstacle = set.ledge, ledgeTop, false
			end
			local p = pick(list, hash(gi, gj, 65))
			table.insert(out, {
				kind = p[1],
				x = x,
				z = z,
				y = y,
				yaw = hash(gi, gj, 66) * 2 * math.pi,
				scale = p[4] + (p[5] - p[4]) * hash(gi, gj, 67),
				tier = p[3],
				obstacle = obstacle,
				seed = gi * 7919 + gj,
				biome = seg.template.Name,
			})
		end
	end
	return out
end

-- The set pieces between z0 and z1 (z0 > z1): one at the middle of each stretch,
-- { kind (its biome's Name), z, w (the corridor's half width there), seed }.
function Endless.landmarks(z0, z1)
	local out = {}
	local seg = Endless.segmentAt(math.min(z0, START))
	while seg and seg.from > z1 do
		local zm = math.floor((seg.from + seg.to) / 2 / CELL) * CELL + CELL / 2
		if zm <= z0 and zm > z1 then
			table.insert(out, { kind = seg.template.Name, z = zm, w = Endless.halfWidth(zm), seed = seg.index })
		end
		seg = segment(seg.index + 1)
	end
	return out
end

-- The fog of the endless biome at z ({ Color, Start, End }), or nil (Shared/BiomeFog).
function Endless.fogAt(z)
	local template = z <= START and Endless.templateAt(z)
	return template and template.Fog or nil
end

return Endless
