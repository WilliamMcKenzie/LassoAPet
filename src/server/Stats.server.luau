-- Our own live stats, for "/stats" in chat (QM, Oct 7: Creator Hub's numbers come
-- in a day or two late). Every server adds up its finished play sessions and every
-- minute adds them into the DataStore "Stats", one key per day (UTC), so the
-- totals are across all servers. Totals only: no player ids are kept.
--
--   "/stats"  (the game's owner, or anyone in Studio) lists them in your chat window:
--             average session today, yesterday and over the last 7 days.
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
local pending = {} -- [dayKey] = { sessions, seconds } not in the store yet

local function track(player)
	local at = os.time()
	if not RunService:IsStudio() and not allowed(player) and player.Parent then
		joined[player] = at
	end
end
Players.PlayerAdded:Connect(track)
for _, player in Players:GetPlayers() do -- (any that joined before this ran)
	task.spawn(track, player)
end

-- A session's over: into today's totals.
local function finish(player)
	local from = joined[player]
	joined[player] = nil
	if from then
		local now = os.time()
		local key = dayKey(now)
		local p = pending[key] or { sessions = 0, seconds = 0 }
		p.sessions += 1
		p.seconds += now - from
		pending[key] = p
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
			old = old or { sessions = 0, seconds = 0 }
			return { sessions = old.sessions + p.sessions, seconds = old.seconds + p.seconds }
		end)
		if not saved then -- try again next time
			local back = pending[key] or { sessions = 0, seconds = 0 }
			back.sessions += p.sessions
			back.seconds += p.seconds
			pending[key] = back
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
	local sessions, seconds = 0, 0
	if store then
		local got, data = pcall(store.GetAsync, store, key)
		if got and data then
			sessions, seconds = data.sessions, data.seconds
		end
	end
	local p = pending[key]
	if p then
		sessions += p.sessions
		seconds += p.seconds
	end
	return sessions, seconds
end

local function average(sessions, seconds)
	if sessions == 0 then
		return "no sessions yet"
	end
	return string.format("%.1f min avg (%d sessions)", seconds / sessions / 60, sessions)
end

local function report()
	local now = os.time()
	local lines = { "Stats (days are UTC, from 8 PM your time):" }
	local weekSessions, weekSeconds = 0, 0
	for i = 0, 6 do
		local sessions, seconds = totals(dayKey(now - i * DAY))
		weekSessions += sessions
		weekSeconds += seconds
		if i == 0 then
			table.insert(lines, "Avg session today: " .. average(sessions, seconds))
		elseif i == 1 then
			table.insert(lines, "Avg session yesterday: " .. average(sessions, seconds))
		end
	end
	table.insert(lines, "Avg session, last 7 days: " .. average(weekSessions, weekSeconds))
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
