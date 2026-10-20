-- Fresh /stats cohort. Counts are player sessions, deduplicated across world travel.
-- Old V1 data is intentionally never read. No player IDs are stored here.
local Config = require(game.ReplicatedStorage.Shared.Config)
local Store = require(script.Parent.StatsStore)
local Stats = {}
Stats.Rows = {
	{ "shop", "Shop" },
	{ "revive", "Crash: Revive" },
	{ "crashInvincible", "Crash: Invincible" },
	{ "eggSpeedup", "Egg speed-up" },
	{ "cashShortfall", "Insufficient-cash offer" },
	{ "StarterPack", "Starter Pack" },
	{ "StarterPackOpen", "Starter Pack popup opened" },
	{ "Speed", "1.5x Speed card" },
	{ "DoubleGold", "2x Cash card" },
	{ "Invincible", "Invincible card" },
	{ "AutoHatch", "Auto Hatch card" },
	{ "away4x", "Away panel: 4x" },
}
for _, pet in Config.PetOffers do
	table.insert(Stats.Rows, { "limited_" .. pet.Kind, "Limited: " .. pet.Kind })
end
local valid = {}
for _, row in Stats.Rows do
	valid[row[1]] = true
end
function Stats.validSurface(surface)
	return type(surface) == "string" and valid[surface] == true
end
local function add(s, fields)
	if not s then
		return
	end
	for _, key in { "simple-v2-all", "simple-v2-day-" .. s.day, s.build } do
		Store.addShared(key, fields)
	end
end
function Stats.begin(carried)
	if type(carried) == "table" and carried.version == 2 then
		return carried
	end
	local s = {
		version = 2,
		day = os.date("!%Y-%m-%d"),
		build = "simple-v2-build-w" .. Config.World .. "-" .. game.PlaceVersion,
		views = {},
		prompts = {},
		buyers = {},
		pending = {},
		world = Config.World,
		biome = 1,
	}
	add(s, { sessions = 1 })
	return s
end
function Stats.reach(s, world, biome)
	if not s then
		return
	end
	local names = Config.BiomeNames[world]
	if not names then
		return
	end
	biome = math.clamp(math.floor(biome), 1, #names)
	-- The event world is a separate branch; track the furthest point within it.
	if world == s.world then
		s.biome = math.max(s.biome, biome)
	elseif world ~= 4 and s.world ~= 4 and world > s.world then
		s.world, s.biome = world, biome
	end
end
function Stats.view(s, surface)
	if not s or not valid[surface] or s.views[surface] then
		return
	end
	s.views[surface] = true
	add(s, { ["view:" .. surface] = 1 })
end
function Stats.prompt(s, sku, surface)
	if not s or not valid[surface] then
		return
	end
	Stats.view(s, surface) -- a checkout also proves the offer was seen
	s.pending[sku] = surface
	if not s.prompts[surface] then
		s.prompts[surface] = true
		add(s, { ["prompt:" .. surface] = 1 })
	end
end
function Stats.purchase(s, sku)
	local surface = s and s.pending[sku]
	if not surface or s.buyers[surface] then
		return
	end
	s.buyers[surface] = true
	add(s, { ["buy:" .. surface] = 1 })
end
function Stats.finish(s, seconds, firstSession, ready)
	if not s or s.closed then
		return
	end
	s.closed = true
	local fields = { completed = 1, seconds = math.max(0, seconds) }
	if firstSession then
		fields.newQuits = 1
		fields[if ready then "quit:w" .. s.world .. ":" .. s.biome else "quit:loading"] = 1
	end
	add(s, fields)
end
local function pct(n, total)
	return if total > 0 then string.format("%.1f%%", n / total * 100) else "N/A"
end
function Stats.report(arg)
	local key, window = "simple-v2-all", "since reset"
	if arg == "build" then
		key, window =
			"simple-v2-build-w" .. Config.World .. "-" .. game.PlaceVersion, "sessions starting in this world/build"
	elseif arg == "today" or (arg and arg:match("^%d%d%d%d%-%d%d%-%d%d$")) then
		local day = if arg == "today" then os.date("!%Y-%m-%d") else arg
		key, window = "simple-v2-day-" .. day, day .. " UTC join cohort"
	end
	local d = Store.readShared(key)
	local completed, sessions, quits = d.completed or 0, d.sessions or 0, d.newQuits or 0
	local lines = {
		"STATS — " .. window .. " (player sessions; world travel stays one session)",
		"Avg session time: " .. (if completed > 0
			then string.format("%.1f min", (d.seconds or 0) / completed / 60)
			else "N/A") .. " (" .. completed .. " completed)",
	}
	local biomes = {}
	for world, names in Config.BiomeNames do
		for i, name in names do
			local n = d["quit:w" .. world .. ":" .. i] or 0
			table.insert(biomes, { name = "W" .. world .. " " .. name, n = n, world = world, biome = i })
		end
	end
	if (d["quit:loading"] or 0) > 0 then
		table.insert(biomes, { name = "Before loading", n = d["quit:loading"], world = 0, biome = 0 })
	end
	table.sort(biomes, function(a, b)
		if a.n ~= b.n then
			return a.n > b.n
		end
		return a.world < b.world or (a.world == b.world and a.biome < b.biome)
	end)
	table.insert(lines, "New-player quit biomes (furthest reached; " .. quits .. " first sessions):")
	local shown = 0
	for _, biome in biomes do
		if biome.n > 0 then
			table.insert(lines, "  " .. biome.name .. ": " .. pct(biome.n, quits) .. " (" .. biome.n .. ")")
			shown += 1
		end
	end
	if shown == 0 then
		table.insert(lines, "  N/A — no completed first sessions yet")
	end
	table.insert(lines, "Monetization (" .. sessions .. " player sessions; purchase % is of viewers):")
	for _, row in Stats.Rows do
		local id, label = row[1], row[2]
		local views, buyers, prompts = d["view:" .. id] or 0, d["buy:" .. id] or 0, d["prompt:" .. id] or 0
		table.insert(
			lines,
			string.format(
				"  %s: %d viewers (%s reach), %d opened checkout, %d buyers (%s purchased)",
				label,
				views,
				pct(views, sessions),
				prompts,
				buyers,
				pct(buyers, views)
			)
		)
	end
	return lines
end
return Stats
