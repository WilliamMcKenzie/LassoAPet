-- Our own live stats, for "/stats" in chat (QM, Oct 7: Creator Hub's numbers come
-- in a day or two late). Every server adds up its finished play sessions and every
-- minute adds them into the DataStore "Stats", one key per day (UTC), so the
-- totals are across all servers. Totals only: no player ids are kept.
--
--   "/stats"  (the game's owner, or anyone in Studio) lists them in your chat window:
--             average session today, yesterday and over the last 7 days, and the
--             first play bounce rate (as Creator Hub's: of players on their very
--             first visit, the share who left within 60 s, and within 61-180 s).
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
-- What each day's totals add up (missing ones, as in days saved before they existed, are 0).
local FIELDS = { "sessions", "seconds", "firsts", "bounce60", "bounce180" }
local function blank()
	local t = {}
	for _, f in FIELDS do
		t[f] = 0
	end
	return t
end
local function addInto(into, from)
	for _, f in FIELDS do
		into[f] = (into[f] or 0) + (from and tonumber(from[f]) or 0)
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
		pending[key] = addInto(pending[key] or blank(), {
			sessions = 1,
			seconds = length,
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
			return addInto(addInto(blank(), old), p)
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

local function bounce(t)
	if t.firsts == 0 then
		return "no first visits yet"
	end
	return string.format("%.1f%% left within 60 s, %.1f%% within 61-180 s (%d first visits)",
		100 * t.bounce60 / t.firsts, 100 * t.bounce180 / t.firsts, t.firsts)
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
	table.insert(lines, "First play bounce today: " .. bounce(today))
	table.insert(lines, "First play bounce, last 7 days: " .. bounce(week))
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
