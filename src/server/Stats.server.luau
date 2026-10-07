-- Our own live stats, for "/stats" in chat (QM, Oct 7: Creator Hub's numbers come
-- in a day or two late). Every server adds up its finished play sessions and every
-- minute adds them into the DataStore "Stats", one key per day (UTC), so the
-- totals are across all servers. Totals only: no player ids are kept.
--
--   "/stats"  (the game's owner, or anyone in Studio) lists them in your chat window:
--             average session today, yesterday and over the last 7 days, today's
--             longest session, and the
--             first play bounce rate (as Creator Hub's: of players on their very
--             first visit, the share who left within 60 s, and within 61-180 s),
--             and where today's sessions ended: how many, and how long they lasted,
--             by how far the player had got when they left (still in the tutorial,
--             or the furthest zone unlocked), and how long players stayed after
--             unlocking the Desert that session (QM, Oct 7: is the Desert a let-down?).
--
-- A first visit is a player the DataStore "StatsSeen" hasn't seen before (it keeps
-- only "seen" against their UserId, inside Roblox like their save; it starts empty
-- on Oct 7, so for a day or so some returning players count as first visits).
--
-- Sessions aren't counted in Studio or for the owner, so testing doesn't skew them.
-- A session counts on the day it ends.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local FLUSH_EVERY = 60 -- seconds between adding this server's sessions into the store
local DAY = 24 * 60 * 60

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Stats")
if not ok then
	store = nil
end
local seenOk, seenStore = pcall(DataStoreService.GetDataStore, DataStoreService, "StatsSeen")
if not seenOk then
	seenStore = nil
end
-- What each day's totals add up (missing ones, as in days saved before they existed, are 0),
-- and what they keep the biggest of (the longest session, in seconds: QM, Oct 7).
local FIELDS = { "sessions", "seconds", "firsts", "bounce60", "bounce180" }
local MOST = { "longest" }
local function blank()
	local t = {}
	for _, f in FIELDS do
		t[f] = 0
	end
	for _, f in MOST do
		t[f] = 0
	end
	return t
end
local most = {}
for _, f in MOST do
	most[f] = true
end
-- (any other number in `from` is added too: the per-stage counts, "at<Stage>Sessions" and so on)
local function addInto(into, from)
	for _, f in FIELDS do
		into[f] = (into[f] or 0) + (from and tonumber(from[f]) or 0)
	end
	for _, f in MOST do
		into[f] = math.max(into[f] or 0, from and tonumber(from[f]) or 0)
	end
	for f, v in from or {} do
		if type(v) == "number" and not most[f] and not table.find(FIELDS, f) then
			into[f] = (into[f] or 0) + v
		end
	end
	return into
end

-- How far a player had got: "Tutorial", or their furthest zone (Config.Biomes' names).
local STAGES = { "Tutorial" }
for _, biome in Config.Biomes do
	table.insert(STAGES, biome.Name)
end
local function stageOf(player)
	if player:GetAttribute("Tutorial") then
		return "Tutorial"
	end
	local biome = Config.Biomes[math.clamp(player:GetAttribute("PenLevel") or 1, 1, #Config.Biomes)]
	return biome and biome.Name or "Tutorial"
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

local joined = {} -- [player] = { at = os.time() they joined, first = their first visit } (players whose sessions count)
local pending = {} -- [dayKey] = totals (FIELDS) not in the store yet

-- True the first time a player's ever seen here (nil if the store can't say).
local function firstVisit(player)
	if not seenStore then
		return nil
	end
	local first = nil
	local got = pcall(seenStore.UpdateAsync, seenStore, "u" .. player.UserId, function(old)
		first = old == nil
		return if first then true else nil -- (nil: leave it as it is)
	end)
	return if got then first else nil
end

local function track(player)
	local at = os.time()
	if RunService:IsStudio() or allowed(player) or not player.Parent then
		return
	end
	local session = { at = at }
	joined[player] = session
	session.first = firstVisit(player)
end
Players.PlayerAdded:Connect(track)
for _, player in Players:GetPlayers() do -- (any that joined before this ran)
	task.spawn(track, player)
end

-- A session's over: into today's totals.
local function finish(player)
	local session = joined[player]
	joined[player] = nil
	if session then
		local now = os.time()
		local length = now - session.at
		local key = dayKey(now)
		local stage = stageOf(player)
		-- PenLevel.server stamps "DesertAt" when a player unlocks the Desert (this session only).
		local desertAt = player:GetAttribute("DesertAt")
		local after = if typeof(desertAt) == "number" and desertAt >= session.at then now - desertAt else nil
		pending[key] = addInto(pending[key] or blank(), {
			["at" .. stage .. "Sessions"] = 1,
			["at" .. stage .. "Seconds"] = length,
			desertUnlocks = if after then 1 else 0,
			afterDesertSeconds = after or 0,
			sessions = 1,
			seconds = length,
			longest = length,
			firsts = if session.first then 1 else 0,
			bounce60 = if session.first and length <= 60 then 1 else 0,
			bounce180 = if session.first and length > 60 and length <= 180 then 1 else 0,
		})
	end
end
Players.PlayerRemoving:Connect(finish)

local function flush()
	if not store then
		return
	end
	local batch = pending
	pending = {}
	for key, p in batch do
		local saved = pcall(store.UpdateAsync, store, key, function(old)
			-- (keeps any fields this version doesn't know, so an older server still
			-- running after a publish doesn't wipe a newer stat like "longest")
			local into = if typeof(old) == "table" then table.clone(old) else {}
			return addInto(into, p)
		end)
		if not saved then -- try again next time
			pending[key] = addInto(pending[key] or blank(), p)
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

-- One day's totals: the store's plus this server's not yet added.
local function totals(key)
	local t = blank()
	if store then
		local got, data = pcall(store.GetAsync, store, key)
		if got and typeof(data) == "table" then
			addInto(t, data)
		end
	end
	return addInto(t, pending[key])
end

local function average(t)
	if t.sessions == 0 then
		return "no sessions yet"
	end
	return string.format("%.1f min avg (%d sessions)", t.seconds / t.sessions / 60, t.sessions)
end

local function longest(t)
	if t.longest <= 0 then
		return "no sessions yet"
	end
	return string.format("%.1f min", t.longest / 60)
end

local function bounce(t)
	if t.firsts == 0 then
		return "no first visits yet"
	end
	return string.format("%.1f%% left within 60 s, %.1f%% within 61-180 s (%d first visits)",
		100 * t.bounce60 / t.firsts, 100 * t.bounce180 / t.firsts, t.firsts)
end

-- Where `t`'s sessions ended, by stage, and how long they lasted after a Desert unlock.
local function byStage(t, lines)
	for _, stage in STAGES do
		local n = t["at" .. stage .. "Sessions"] or 0
		if n > 0 then
			table.insert(lines, string.format("  Left at %s: %d (%.0f%%), %.1f min avg",
				stage, n, 100 * n / math.max(t.sessions, 1), (t["at" .. stage .. "Seconds"] or 0) / n / 60))
		end
	end
	local unlocks = t.desertUnlocks or 0
	if unlocks > 0 then
		table.insert(lines, string.format("  Unlocked the Desert this session: %d, stayed %.1f min avg after",
			unlocks, (t.afterDesertSeconds or 0) / unlocks / 60))
	end
end

local function report()
	local now = os.time()
	local lines = { "Stats (days are UTC, from 8 PM your time):" }
	local week, today = blank(), nil
	for i = 0, 6 do
		local t = totals(dayKey(now - i * DAY))
		addInto(week, t)
		if i == 0 then
			today = t
			table.insert(lines, "Avg session today: " .. average(t))
		elseif i == 1 then
			table.insert(lines, "Avg session yesterday: " .. average(t))
		end
	end
	table.insert(lines, "Avg session, last 7 days: " .. average(week))
	table.insert(lines, "Longest session today: " .. longest(today))
	table.insert(lines, "First play bounce today: " .. bounce(today))
	table.insert(lines, "First play bounce, last 7 days: " .. bounce(week))
	table.insert(lines, "Where today's sessions ended (furthest zone when they left):")
	byStage(today, lines)
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
