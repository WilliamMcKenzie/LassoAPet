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
--             that only count toward today's.
--             "Quit at:" (QM, Oct 12): the share of today's sessions, and the newest
--             version's, that ended in each length band (QUIT_BANDS, below).
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

local FLUSH_EVERY = 60 -- seconds between adding this server's sessions into the store

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "SessionStats")
if not ok then
	store = nil
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

local VERSION = game.PlaceVersion
local VERSION_KEY = "version-" .. VERSION
local VERSIONS_SHOWN = 5

-- Session length bands for "Quit at:" (QM, Oct 12; his list skipped 20-30, kept so the
-- shares add up to 100%): a session of Upto minutes or less (and over the band before)
-- counts in that band, as "quit<i>"; the last band has no Upto.
local QUIT_BANDS = {
	{ Name = "0-1m", Upto = 1 },
	{ Name = "1-5m", Upto = 5 },
	{ Name = "5-10m", Upto = 10 },
	{ Name = "10-20m", Upto = 20 },
	{ Name = "20-30m", Upto = 30 },
	{ Name = "30+m" },
}

local function quitBand(seconds)
	for i, band in QUIT_BANDS do
		if not band.Upto or seconds <= band.Upto * 60 then
			return i
		end
	end
	return #QUIT_BANDS
end

-- "Quit at: 0-1m 12%, 1-5m 40%, ..." for a day's or a version's totals, out of the
-- sessions that have a band (a day's from before this build have none); nil if none do.
local function quitLine(t)
	local banded = 0
	for i in QUIT_BANDS do
		banded += t["quit" .. i] or 0
	end
	if banded == 0 then
		return nil
	end
	local shares = {}
	for i, band in QUIT_BANDS do
		table.insert(shares, string.format("%s %.0f%%", band.Name, 100 * (t["quit" .. i] or 0) / banded))
	end
	return table.concat(shares, ", ")
end

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
		local band = "quit" .. quitBand(length)
		local session = { sessions = 1, seconds = length, longest = length, [band] = 1 }
		for i = 2, math.min(player:GetAttribute("GatesBroken") or 1, #Config.Biomes) do
			session["reached" .. i] = 1
		end
		pending[key] = addInto(pending[key] or {}, session)
		pending[VERSION_KEY] = addInto(pending[VERSION_KEY] or {}, { sessions = 1, seconds = length, longest = length, [band] = 1 })
	end
end
Players.PlayerRemoving:Connect(finish)

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
			table.insert(reached, string.format("%s %.0f%%", Config.Biomes[i].Name, 100 * (t["reached" .. i] or 0) / t.sessions))
		end
		table.insert(lines, "Reached: " .. table.concat(reached, ", "))
		local quit = quitLine(t)
		if quit then
			table.insert(lines, "Quit at: " .. quit)
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
	if #versions > 0 then
		table.insert(lines, "Avg session by version (all time):")
	end
	for i = 1, math.min(#versions, VERSIONS_SHOWN) do
		local v = today("version-" .. versions[i])
		table.insert(lines, if v.sessions == 0
			then string.format("  v%d: no sessions", versions[i])
			else string.format("  v%d: %.1f min (%d sessions)", versions[i], v.seconds / v.sessions / 60, v.sessions))
		local quit = i == 1 and quitLine(v) -- (the newest version's only: QM, Oct 12)
		if quit then
			table.insert(lines, "    Quit at: " .. quit)
		end
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
