-- Our own live stats, for "/stats" in chat (QM, Oct 7: Creator Hub's numbers come
-- in a day or two late). Every server adds up its finished play sessions and every
-- minute adds them into the DataStore "SessionStats", one key per day (UTC), so the
-- totals are across all servers. Totals only: no player ids are kept.
--
--   "/stats"  (the game's owner, or anyone in Studio) lists them in your chat window:
--             today's average session and today's longest session (QM, Oct 11), and the
--             share of today's sessions whose player had reached each biome by the time
--             they left (the furthest barrier they've ever ridden through, Gold.server's
--             "GatesBroken"; QM, Oct 11). A player back twice counts twice. Under it, the
--             average session on each of the 5 latest versions (game.PlaceVersion), over
--             each version's whole life, so an update's effect shows (QM, Oct 11): kept
--             under "version-<n>", the versions seen under "versions". Sessions from before
--             that only count toward today's. In World 1, also the share of today's sessions
--             whose player had World 2, and World 2's own today: its sessions and the share
--             reaching each of its biomes (QM, Oct 13).
--
-- QM, Oct 11: a blank slate. The old store ("Stats") is left behind, so nothing from
-- older builds counts, even from their servers still running.
--
-- Sessions aren't counted in Studio or for the owner, so testing doesn't skew them.
-- A session counts on the day it ends.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Funnel = require(script.Parent.Funnel)
local StatsStore = require(script.Parent.StatsStore)

local FLUSH_EVERY = 60 -- seconds between adding this server's sessions into the store

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("SessionStats")) -- (each world's own)
if not ok then
	store = nil
end
-- World 2's, read from World 1 for its part of the report (QM, Oct 13).
local ok2, store2 = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("SessionStats", 2))
if not ok2 or Config.World == 2 then
	store2 = nil
end
-- Each world's biome names, as players know them (World 2's are its own: its Config.Biomes
-- keep World 1's names underneath).
local NAMES = {
	[2] = { "Meadow", "Crimson Lands", "Crystal Cavern", "Woodland Maze", "Temple", "Tomb" },
}
local function biomeName(i, world)
	local names = NAMES[world or Config.World]
	return names and names[i] or Config.Biomes[i].Name
end

-- A day's totals: longest keeps the biggest, everything else adds up (sessions, their
-- seconds, and "reached<i>": sessions whose player had reached biome i).
local function addInto(into, from)
	into.sessions = into.sessions or 0
	into.seconds = into.seconds or 0
	into.longest = math.max(into.longest or 0, from and tonumber(from.longest) or 0)
	for f, v in from or {} do
		if f ~= "longest" and type(v) == "number" then
			into[f] = (into[f] or 0) + v
		end
	end
	return into
end

-- The game's owner (as Hatchery's dev commands), or anyone in Studio.
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

local function dayKey(time)
	return os.date("!day-%Y-%m-%d", time)
end

-- Where sessions end (QM, Oct 12): the share of today's in each band, minutes.
local BANDS = { { 1, "0-1m" }, { 5, "1-5m" }, { 10, "5-10m" }, { 20, "10-20m" }, { 30, "20-30m" }, { math.huge, "30m+" } }

local VERSION = game.PlaceVersion
local VERSION_KEY = "version-" .. VERSION
local VERSIONS_SHOWN = 5
local versionNoted = false -- this server's version is in "versions"

local joined = {} -- [player] = os.time() they joined (players whose sessions count)
local pending = {} -- [dayKey] = totals not in the store yet

local function track(player)
	local at = os.time()
	if RunService:IsStudio() or allowed(player) or not player.Parent then
		return
	end
	joined[player] = at
end
Players.PlayerAdded:Connect(track)
for _, player in Players:GetPlayers() do -- (any that joined before this ran)
	task.spawn(track, player)
end

-- A session's over: into today's totals.
local function finish(player)
	local at = joined[player]
	joined[player] = nil
	if at then
		local now = os.time()
		local length = now - at
		local key = dayKey(now)
		local session = { sessions = 1, seconds = length, longest = length }
		for i, band in BANDS do
			if length < band[1] * 60 then
				session["quit" .. i] = 1
				break
			end
		end
		for i = 2, math.min(player:GetAttribute("GatesBroken") or 1, #Config.Biomes) do
			session["reached" .. i] = 1
		end
		if Config.World == 1 and player:GetAttribute("OwnsWorld2") then
			session.world2 = 1 -- (they'd made it to World 2 by the time they left: QM, Oct 13)
		end
		pending[key] = addInto(pending[key] or {}, session)
		local forVersion = { sessions = 1, seconds = length, longest = length }
		for f, v in session do
			if f:match("^quit") then
				forVersion[f] = v -- (its quit band: "Quit at" is the latest version's)
			end
		end
		pending[VERSION_KEY] = addInto(pending[VERSION_KEY] or {}, forVersion)
	end
end
Players.PlayerRemoving:Connect(finish)

-- How long players took to unlock each biome (QM, Oct 13): their play time in this world,
-- all visits, when they first broke its barrier (Gold.server fires it, only for players
-- counted from their first visit). Kept per version, as "unlock<i>" (seconds) and
-- "unlocks<i>" (how many), so /stats shows the latest version's.
local biomeUnlocked = Instance.new("BindableEvent")
biomeUnlocked.Name = "BiomeUnlocked"
biomeUnlocked.Event:Connect(function(player, biome, seconds)
	if joined[player] and type(biome) == "number" and type(seconds) == "number" then
		pending[VERSION_KEY] = addInto(pending[VERSION_KEY] or {}, { ["unlock" .. biome] = seconds, ["unlocks" .. biome] = 1 })
	end
end)
biomeUnlocked.Parent = game:GetService("ServerStorage")

local function flush()
	if not store then
		return
	end
	if not versionNoted and next(pending) then
		versionNoted = pcall(store.UpdateAsync, store, "versions", function(old)
			local list = if typeof(old) == "table" then old else {}
			if not table.find(list, VERSION) then
				table.insert(list, VERSION)
				table.sort(list, function(a, b)
					return a > b
				end)
				while #list > 20 do
					table.remove(list)
				end
			end
			return list
		end)
	end
	local batch = pending
	pending = {}
	for key, p in batch do
		local saved = pcall(store.UpdateAsync, store, key, function(old)
			return addInto(if typeof(old) == "table" then old else {}, p)
		end)
		if not saved then -- try again next time
			pending[key] = addInto(pending[key] or {}, p)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(FLUSH_EVERY)
		flush()
	end
end)
game:BindToClose(function()
	for player in joined do -- (the server's shutting down: everyone's session ends now)
		finish(player)
	end
	flush()
end)

-- Today's totals (or a version's: key): the store's plus this server's not yet added.
local function today(key)
	key = key or dayKey(os.time())
	local t = addInto({}, nil)
	if store then
		local got, data = pcall(store.GetAsync, store, key)
		if got and typeof(data) == "table" then
			addInto(t, data)
		end
	end
	return addInto(t, pending[key])
end

local function report()
	local t = today()
	local lines = { "Stats today (UTC day, from 8 PM your time):" }
	if t.sessions == 0 then
		table.insert(lines, "No sessions yet")
	else
		table.insert(lines, string.format("Avg session: %.1f min (%d sessions)", t.seconds / t.sessions / 60, t.sessions))
		table.insert(lines, string.format("Longest session: %.1f min", t.longest / 60))
		local reached = {}
		for i = 2, #Config.Biomes do
			table.insert(reached, string.format("%s %.0f%%", biomeName(i), 100 * (t["reached" .. i] or 0) / t.sessions))
		end
		table.insert(lines, "Reached: " .. table.concat(reached, ", "))
		if Config.World == 1 then
			table.insert(lines, string.format("Made it to World 2: %.0f%% (%d)", 100 * (t.world2 or 0) / t.sessions, t.world2 or 0))
		end
	end
	-- World 2 today (from World 1: its own store), of the sessions played there, how far they
	-- got (QM, Oct 13: of the players who made it to World 2, the share reaching each biome).
	if store2 then
		local got, w2 = pcall(store2.GetAsync, store2, dayKey(os.time()))
		w2 = if got and typeof(w2) == "table" then w2 else nil
		if w2 and (w2.sessions or 0) > 0 then
			local reached = {}
			for i = 2, #Config.Biomes do
				table.insert(reached, string.format("%s %.0f%%", biomeName(i, 2), 100 * (w2["reached" .. i] or 0) / w2.sessions))
			end
			table.insert(lines, string.format("World 2 today: avg %.1f min (%d sessions)", (w2.seconds or 0) / w2.sessions / 60, w2.sessions))
			table.insert(lines, "World 2 reached: " .. table.concat(reached, ", "))
		else
			table.insert(lines, "World 2 today: no sessions yet")
		end
	end
	-- The latest versions' averages, newest first (each over its whole life).
	local versions = {}
	if store then
		local got, list = pcall(store.GetAsync, store, "versions")
		if got and typeof(list) == "table" then
			versions = list
		end
	end
	if pending[VERSION_KEY] and not table.find(versions, VERSION) then
		table.insert(versions, VERSION)
	end
	table.sort(versions, function(a, b)
		return a > b
	end)
	-- Where sessions end on the latest version (QM, Oct 12), over its whole life.
	if #versions > 0 then
		local v = today("version-" .. versions[1])
		local banded = 0
		for i in BANDS do
			banded += v["quit" .. i] or 0
		end
		if banded > 0 then
			local quit = {}
			for i, band in BANDS do
				table.insert(quit, string.format("%s %.0f%%", band[2], 100 * (v["quit" .. i] or 0) / banded))
			end
			table.insert(lines, string.format("Quit at, v%d (%d sessions): %s", versions[1], banded, table.concat(quit, ", ")))
		end
		-- Average play time to unlock each biome on the latest version (QM, Oct 13).
		local unlock = {}
		for i = 2, #Config.Biomes do
			local n = v["unlocks" .. i] or 0
			table.insert(unlock, if n > 0
				then string.format("%s %.1f min (%d)", biomeName(i), (v["unlock" .. i] or 0) / n / 60, n)
				else string.format("%s -", biomeName(i)))
		end
		table.insert(lines, string.format("Time to unlock, v%d: %s", versions[1], table.concat(unlock, ", ")))
		table.insert(lines, "Avg session by version (all time):")
	end
	for i = 1, math.min(#versions, VERSIONS_SHOWN) do
		local v = today("version-" .. versions[i])
		table.insert(lines, if v.sessions == 0
			then string.format("  v%d: no sessions", versions[i])
			else string.format("  v%d: %.1f min (%d sessions)", versions[i], v.seconds / v.sessions / 60, v.sessions))
	end
	-- The [V1] funnels (Analytics V1, Funnel): this world's totals since they went in, each
	-- step's count, its share of the first step and of the step before.
	local f = StatsStore.read("v1-funnels")
	for _, name in { "[V1] Tutorial", "[V1] First Session Loop", Funnel.BIOMES, "[V1] Quest Claims", "[V1] Quest Progress" } do
		local steps = Funnel.STEPS[name]
		local base = f[name .. "|1"] or 0
		local parts = {}
		for i, step in steps do
			local n = f[name .. "|" .. i] or 0
			local prev = f[name .. "|" .. (i - 1)]
			table.insert(parts, if i == 1 then string.format("%s %d", step, n)
				else string.format("%s %d (%s, %s)", step, n,
					if base > 0 then string.format("%.0f%%", 100 * n / base) else "N/A",
					if prev and prev > 0 then string.format("%.0f%% of prev", 100 * n / prev) else "N/A"))
		end
		table.insert(lines, name .. ": " .. table.concat(parts, " > "))
	end
	if not store then
		table.insert(lines, "(No DataStore here: this server's sessions only)")
	end
	return lines
end

local command = Instance.new("TextChatCommand")
command.Name = "Stats"
command.PrimaryAlias = "/stats"
command.Triggered:Connect(function(source)
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player or not allowed(player) then
		return
	end
	local devChat = ReplicatedStorage:WaitForChild("DevChat", 10) -- (Hatchery's: shown only to you)
	if devChat then
		for _, line in report() do
			devChat:FireClient(player, line)
		end
	end
end)
command.Parent = game:GetService("TextChatService")
