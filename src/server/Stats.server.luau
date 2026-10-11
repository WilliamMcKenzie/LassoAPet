-- Our own live stats, for "/stats" in chat (QM, Oct 7: Creator Hub's numbers come
-- in a day or two late). Every server adds up its finished play sessions and every
-- minute adds them into the DataStore "SessionStats", one key per day (UTC), so the
-- totals are across all servers. Totals only: no player ids are kept.
--
--   "/stats"  (the game's owner, or anyone in Studio) lists them in your chat window:
--             today's average session and today's longest session (QM, Oct 11), and the
--             share of today's sessions whose player had reached each biome by the time
--             they left (the furthest barrier they've ever ridden through, Gold.server's
--             "GatesBroken"; QM, Oct 11). A player back twice counts twice.
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
		for i = 2, math.min(player:GetAttribute("GatesBroken") or 1, #Config.Biomes) do
			session["reached" .. i] = 1
		end
		pending[key] = addInto(pending[key] or {}, session)
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

-- Today's totals: the store's plus this server's not yet added.
local function today()
	local key = dayKey(os.time())
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
