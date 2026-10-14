-- "/stats" in chat (the game's owner, or anyone in Studio): Analytics V1's report (QM,
-- Oct 13: "start fresh"), from our own totals across every server of both worlds
-- (Telemetry, in the store the worlds share; the funnels' in each world's own). The
-- stats before V1 (the "SessionStats" day and version keys) are left as they were.
--
--   /stats          today (UTC day)
--   /stats <date>   that day, YYYY-MM-DD
--   /stats build    this world's current build, all time (sessions that ended in this world)
--
-- Each line says its sample count; anything with none is N/A. Percentiles come from the
-- merged histograms (Telemetry.bucket), so they're within 10% or so.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Funnel = require(script.Parent.Funnel)
local StatsStore = require(script.Parent.StatsStore)
local Telemetry = require(script.Parent.Telemetry)

-- Gold.server fires it (player, biome, online seconds in this world when they first broke
-- its barrier); Telemetry records it.
local biomeUnlocked = Instance.new("BindableEvent")
biomeUnlocked.Name = "BiomeUnlocked"
biomeUnlocked.Parent = game:GetService("ServerStorage")

-- Each world's biome names, as players know them.
local NAMES = {
	[1] = { "Meadow", "Desert", "Tundra", "Ocean", "Volcano", "Jurassic" },
	[2] = { "Meadow", "Crimson Lands", "Crystal Cavern", "Woodland Maze", "Temple", "Tomb" },
}
local QUIT = { "0-1m", "1-5m", "5-10m", "10-20m", "20-30m", "30m+" }
local EXITS = { "startup", "tutorial", "base", "outbound", "return", "reward", "transfer" }

local function allowed(player)
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local success, group = pcall(function()
		return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
	end)
	return success and group.Owner ~= nil and player.UserId == group.Owner.Id
end

local function pct(n, of)
	return if of and of > 0 then string.format("%.0f%%", 100 * n / of) else "N/A"
end
local function minutes(seconds)
	return if seconds then string.format("%.1fm", seconds / 60) else "N/A"
end

-- Reading one window's totals: d[seg .. "|c:" .. name] and the histograms.
local function reader(d)
	local r = {}
	function r.c(name, seg)
		return d[(seg or "all") .. "|c:" .. name] or 0
	end
	function r.n(name, seg)
		return d[(seg or "all") .. "|n:" .. name] or 0
	end
	function r.mean(name, seg)
		local n = r.n(name, seg)
		return if n > 0 then (d[(seg or "all") .. "|s:" .. name] or 0) / n else nil
	end
	-- The p-th percentile (0-1) of a histogram, or nil with no samples.
	function r.p(name, p, seg)
		local prefix = (seg or "all") .. "|h:" .. name .. ":"
		local buckets, total = {}, 0
		for field, count in d do
			if string.sub(field, 1, #prefix) == prefix then
				local b = tonumber(string.sub(field, #prefix + 1))
				if b then
					buckets[b] = (buckets[b] or 0) + count
					total += count
				end
			end
		end
		if total == 0 then
			return nil
		end
		local order = {}
		for b in buckets do
			table.insert(order, b)
		end
		table.sort(order)
		local want, seen = p * total, 0
		for _, b in order do
			seen += buckets[b]
			if seen >= want then
				return Telemetry.bucketValue(b)
			end
		end
		return Telemetry.bucketValue(order[#order])
	end
	-- "P50 x / P75 y (n)" in minutes or plain numbers.
	function r.spread(name, seg, asNumber, ps)
		local n = r.n(name, seg)
		if n == 0 then
			return "N/A (0)"
		end
		local parts = {}
		for _, p in ps or { 0.5, 0.75 } do
			local v = r.p(name, p, seg)
			table.insert(parts, string.format("P%d %s", p * 100, if asNumber then Config.short(math.floor(v)) else minutes(v)))
		end
		return table.concat(parts, " / ") .. " (" .. n .. ")"
	end
	return r
end

local function report(arg)
	local lines = {}
	local function line(text, ...)
		table.insert(lines, if select("#", ...) > 0 then string.format(text, ...) else text)
	end
	local key, window
	if arg == "build" then
		key, window = "v1b-w" .. Config.World .. "-" .. Telemetry.BUILD, "World " .. Config.World .. " build " .. Telemetry.BUILD .. ", all time (sessions ending here)"
	elseif arg and arg:match("^%d%d%d%d%-%d%d%-%d%d$") then
		key, window = "v1d-" .. arg, arg .. " (UTC)"
	else
		key, window = "v1d-" .. os.date("!%Y-%m-%d"), "today, " .. os.date("!%Y-%m-%d") .. " (UTC, from 8 PM your time)"
	end
	local d = StatsStore.readShared(key)
	local r = reader(d)
	local updated = d["max:updated"]
	line("[V1] Stats: %s. World %d build %d. Last update: %s.", window, Config.World, Telemetry.BUILD,
		if updated then string.format("%d min ago", math.floor((os.time() - updated) / 60)) else "none yet")

	-- Sessions (one visit to the game, both worlds).
	local active, everywhere = Telemetry.active()
	local ended = r.c("end")
	line("SESSIONS: started %d (new %d, returning %d), completed %d, active now %d%s",
		r.c("start"), r.c("start", "new"), r.c("start", "ret"), ended, active.all, if everywhere then "" else " (this server)")
	line("  Playtime of completed: mean %s, median %s (%d)", minutes(r.mean("session")), minutes(r.p("session", 0.5)), r.n("session"))
	for _, seg in { "new", "ret" } do
		line("  %s: mean %s, median %s (%d)", if seg == "new" then "New" else "Returning", minutes(r.mean("session", seg)), minutes(r.p("session", 0.5, seg)), r.n("session", seg))
	end
	local quit = {}
	for i, band in QUIT do
		table.insert(quit, band .. " " .. pct(r.c("quit" .. i), ended))
	end
	line("  Quit at: %s", table.concat(quit, ", "))
	for w = 1, 2 do
		line("  Place visits, World %d: %d, mean %s, median %s", w, r.c("placeVisit" .. w), minutes(r.mean("placeVisit" .. w)), minutes(r.p("placeVisit" .. w, 0.5)))
	end
	local devices = {}
	for _, device in { "pc", "phone", "tablet", "console" } do
		local n = r.n("session", device)
		if n > 0 then
			table.insert(devices, string.format("%s %d (median %s)", device, n, minutes(r.p("session", 0.5, device))))
		end
	end
	line("  By device: %s", if #devices > 0 then table.concat(devices, ", ") else "N/A")

	-- Startup and tutorial (counts; % of joins).
	local joins = r.c("join")
	local startup = {}
	for _, name in { "profileReady", "clientReady", "loadFail", "eggPlaced", "eggHatched" } do
		table.insert(startup, string.format("%s %d (%s)", name, r.c(name), pct(r.c(name), joins)))
	end
	line("STARTUP: joins %d; %s", joins, table.concat(startup, ", "))
	line("  Events: mounted %d, lasso chance %d, throws %d, landed %d, boss/return %d, quests opened %d",
		r.c("mounted"), r.c("lassoChance"), r.c("lassoThrow"), r.c("lassoLand"), r.c("returnStart"), r.c("questsOpened"))

	-- First-session survival (completed first sessions only).
	local entrants = r.c("fsEntrant")
	local alive = {}
	for _, t in Telemetry.SURVIVAL do
		table.insert(alive, t .. "m " .. pct(r.c("fsAlive" .. t), entrants))
	end
	line("FIRST SESSION SURVIVAL (%d completed first sessions): %s", entrants, table.concat(alive, ", "))

	-- Runs.
	for _, part in { "tut", "post" } do
		local runs, wins = r.c(part .. "Run"), r.c(part .. "Success")
		line("RUNS %s: attempts %d, successes %d (%s), crashes %d (%s), retry in 60s %s (%d)",
			if part == "tut" then "tutorial" else "after tutorial", runs, wins, pct(wins, runs), r.c(part .. "Crash"), pct(r.c(part .. "Crash"), runs),
			pct(r.c(part .. "Retry"), r.c(part .. "RetryEligible")), r.c(part .. "RetryEligible"))
	end
	line("  Successes per session: mean %s, median %s (%d)", if r.mean("successes") then string.format("%.1f", r.mean("successes")) else "N/A",
		if r.p("successes", 0.5) then string.format("%.0f", r.p("successes", 0.5)) else "N/A", r.n("successes"))

	-- Exit phase.
	local exits = {}
	for _, phase in EXITS do
		table.insert(exits, phase .. " " .. pct(r.c("exit:" .. phase), ended))
	end
	line("EXIT PHASE (%d): %s", ended, table.concat(exits, ", "))

	-- What they were doing as they left (Telemetry's quit snapshot), by when they left.
	local SNAP = {
		{ "rides since tutorial", { "rides0", "rides1", "rides2", "rides3-5", "rides6+" } },
		{ "last ride", { "last:animal", "last:crash", "last:empty", "last:riding", "last:none" } },
		{ "since it ended", { "idle:<15", "idle:<60", "idle:60+" } },
		{ "that ride into their furthest biome", { "far:gate", "far:<50", "far:<80", "far:<95", "far:95+" } },
		{ "vs their best before", { "vs:best", "vs:near", "vs:short", "vs:first" } },
		{ "rides since a new barrier", { "stuck:0", "stuck:1-2", "stuck:3-5", "stuck:6+" } },
		{ "egg in pen", { "egg:ready", "egg:hatching", "egg:none" } },
		{ "quest to claim", { "claim:yes", "claim:no" } },
		{ "World 2 gold (W1, not owned)", { "w2gold:yes", "w2gold:no" } },
		{ "had it for", { "w2for:<1m", "w2for:1-5m", "w2for:5m+" } },
		{ "at base since", { "w2seen:yes", "w2seen:no" } },
	}
	line("AS THEY LEFT (quit snapshot):")
	for q, band in { "<1m", "1-5m", "5-10m", "10-20m", "20m+" } do
		local n = r.c("q" .. q .. ":n")
		if n > 0 then
			local parts = {}
			for _, group in SNAP do
				local bits = {}
				for _, what in group[2] do
					local c = r.c("q" .. q .. ":" .. what)
					if c > 0 then
						table.insert(bits, what:gsub("^%w+:", "") .. " " .. pct(c, n))
					end
				end
				if #bits > 0 then
					table.insert(parts, group[1] .. ": " .. table.concat(bits, ", "))
				end
			end
			local reach = {}
			for w = 1, 2 do
				for i = 1, #NAMES[w] do
					local c = r.c("q" .. q .. ":w" .. w .. "reach" .. i)
					if c > 0 then
						table.insert(reach, "W" .. w .. " " .. NAMES[w][i] .. " " .. pct(c, n))
					end
				end
			end
			line("  Quit %s (%d): %s; barrier: %s", band, n, table.concat(parts, "; "), table.concat(reach, ", "))
		end
	end

	-- Pacing and replay.
	line("PACING: first ride %s; first reward %s; next ride after tutorial %s", r.spread("toFirstRide"), r.spread("toFirstReward"), r.spread("toNextRide"))
	line("  Replay (rode again within 90s of the tutorial): %s (%d)", pct(r.c("replay"), r.c("replayEligible")), r.c("replayEligible"))
	for w = 1, 2 do
		local times = {}
		for i = 2, #NAMES[w] do
			table.insert(times, NAMES[w][i] .. " " .. r.spread("w" .. w .. "biome" .. i))
		end
		line("  World %d time to reach (online, this world): %s", w, table.concat(times, "; "))
	end

	-- World progression.
	local first = {}
	for i = 2, #NAMES[1] do
		table.insert(first, NAMES[1][i] .. " " .. pct(r.c("fv" .. i), entrants))
	end
	line("REACH, first sessions (%d): %s", entrants, table.concat(first, ", "))
	for w = 1, 2 do
		local visits = r.c("placeVisit" .. w)
		local reach = {}
		for i = 2, #NAMES[w] do
			table.insert(reach, NAMES[w][i] .. " " .. pct(r.c("w" .. w .. "reach" .. i), visits))
		end
		line("  Ever reached, World %d place visits (%d): %s", w, visits, table.concat(reach, ", "))
	end
	local worlds = StatsStore.readShared("v1-worlds")
	local w1new = worlds.w1new or 0
	line("  World 2, of new World 1 players since V1 (%d, all time): unlocked %d (%s), entered %d (%s)",
		w1new, worlds.w2unlocked or 0, pct(worlds.w2unlocked or 0, w1new), worlds.w2entered or 0, pct(worlds.w2entered or 0, w1new))

	-- Gold checkpoints (first sessions still playing then).
	for _, t in Telemetry.GOLD_AT do
		local g = "g" .. t
		line("GOLD at %dm (%d, %s of first-session entrants; paid %d): wallet %s; earned %s; spent %s; income/s %s", t, r.c(g),
			pct(r.c(g), entrants), r.c("gp" .. t),
			r.spread(g .. ":wallet", nil, true, { 0.25, 0.5, 0.75 }), r.spread(g .. ":earned", nil, true, { 0.25, 0.5, 0.75 }),
			r.spread(g .. ":spent", nil, true, { 0.25, 0.5, 0.75 }), r.spread(g .. ":income", nil, true, { 0.25, 0.5, 0.75 }))
	end

	-- The [V1] funnels: this world's, all time.
	local f = StatsStore.read("v1-funnels")
	line("FUNNELS (World %d, all time):", Config.World)
	for _, name in { "[V1] Tutorial", "[V1] First Session Loop", Funnel.BIOMES, "[V1] Quest Claims", "[V1] Quest Progress" } do
		local steps = Funnel.STEPS[name]
		local base = f[name .. "|1"] or 0
		local parts = {}
		for i, step in steps do
			local n = f[name .. "|" .. i] or 0
			table.insert(parts, if i == 1 then string.format("%s %d", step, n)
				else string.format("%s %d (%s, %s of prev)", step, n, pct(n, base), pct(n, f[name .. "|" .. (i - 1)])))
		end
		line("  %s: %s", name, table.concat(parts, " > "))
		-- (session funnels: stopped short in a session that's over, or still going)
		local endedAt, stopped = 0, 0
		for i = 1, #steps do
			local e = f[name .. "|end" .. i] or 0
			endedAt += e
			if i < #steps then
				stopped += e
			end
		end
		if endedAt > 0 then
			line("    Not finished: %d in ended sessions, %d still pending", stopped, math.max(0, base - endedAt))
		end
	end
	local quests = {}
	for line_, list in Config.Quests do
		for at, quest in list do
			local k = "[V1] Quest Progress|w" .. Config.World .. ":q" .. (line_ * 100 + at) .. "|"
			local current = f[k .. 1] or 0
			if current > 0 then
				table.insert(quests, string.format("%s %d > %d > %d", quest.Text, current, f[k .. 2] or 0, f[k .. 3] or 0))
			end
		end
	end
	line("  Quests (current > ready > claimed): %s", if #quests > 0 then table.concat(quests, "; ") else "N/A")
	if RunService:IsStudio() then
		line("(Studio: nothing's saved, so this is this test server's only)")
	end
	return lines
end

local command = Instance.new("TextChatCommand")
command.Name = "Stats"
command.PrimaryAlias = "/stats"
command.Triggered:Connect(function(source, text)
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player or not allowed(player) then
		return
	end
	local devChat = ReplicatedStorage:WaitForChild("DevChat", 10) -- (Hatchery's: shown only to you)
	if devChat then
		local ok, lines = pcall(report, text:lower():match("^/stats%s+(%S+)"))
		for _, l in if ok then lines else { "/stats failed: " .. tostring(lines) } do
			devChat:FireClient(player, l)
		end
	end
end)
command.Parent = game:GetService("TextChatService")
