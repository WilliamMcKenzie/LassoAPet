-- Our own cross-server totals (QM, Oct 13: Analytics V1): counts added here by any server
-- script go into this world's SessionStats DataStore under a key, merged into what's
-- there about every FLUSH seconds (UpdateAsync, so servers never overwrite each other),
-- plus whatever this server hasn't sent yet when it's read. Totals only: no player ids.
-- Nothing is saved from Studio (testing would skew it): there the adds print and stay
-- in this server only.
--
-- Spread out (Oct 18): a DataStore key takes one write every 6 s from the whole game, and
-- every server was writing the same five keys ("v1-funnels", "v1-leaves", the day's and the
-- build's totals, "v1-worlds") every 60 s, so with more than ten servers up most flushes
-- were throttled (the day's 100k throttling events), queued for the next minute and
-- throttled again. Now each server writes its own shard of a key ("<key>#<n>", n from its
-- JobId) on its own clock (FLUSH, give or take JITTER), and a read sums the shards plus the
-- plain key the totals were under before.
--
--   StatsStore.add(key, { field = n, ... })   -- n added to each field ("max:" fields keep the biggest)
--   StatsStore.read(key) -> { field = n }      -- the store's plus this server's pending
--   StatsStore.addShared / readShared          -- the same, in the store every world shares
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local FLUSH, JITTER = 180, 45 -- seconds between this server's flushes, give or take
local SHARDS = 10 -- keys each total is spread over (a read sums them: SHARDS + 1 GetAsyncs a key)

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("SessionStats"))
if not ok or RunService:IsStudio() then
	store = nil
end
local okShared, shared = pcall(DataStoreService.GetDataStore, DataStoreService, "SessionStatsShared") -- (every world's)
if not okShared or RunService:IsStudio() then
	shared = nil
end

-- This server's shard: a stable pick from its JobId (each Studio run its own).
local SHARD
do
	local id = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
	local h = 0
	for i = 1, #id do
		h = (h * 31 + string.byte(id, i)) % 2147483647
	end
	SHARD = h % SHARDS
end
local function shardKey(key, n)
	return key .. "#" .. n
end

local StatsStore = {}
local pending = {} -- [key] = { field = n }
local pendingShared = {}

local function merge(into, from)
	for f, n in from or {} do
		if type(n) == "number" then
			into[f] = if string.sub(f, 1, 4) == "max:" then math.max(into[f] or n, n) else (into[f] or 0) + n
		end
	end
	return into
end

StatsStore.quiet = false -- (Studio prints each add unless this is set)
local function addTo(queue, key, fields)
	if RunService:IsStudio() and not StatsStore.quiet then
		local list = {}
		for f, n in fields do
			table.insert(list, f .. " +" .. n)
		end
		print("[Stats] " .. key .. ": " .. table.concat(list, ", "))
	end
	queue[key] = merge(queue[key] or {}, fields)
end
function StatsStore.add(key, fields)
	addTo(pending, key, fields)
end
function StatsStore.addShared(key, fields)
	addTo(pendingShared, key, fields)
end

-- The plain key (the totals before sharding) and every shard, read together and summed.
local function readFrom(from, queue, key)
	local t = {}
	if from then
		local keys = { key }
		for n = 0, SHARDS - 1 do
			table.insert(keys, shardKey(key, n))
		end
		local left = #keys
		for _, k in keys do
			task.spawn(function()
				local got, data = pcall(from.GetAsync, from, k)
				if got and typeof(data) == "table" then
					merge(t, data)
				end
				left -= 1
			end)
		end
		while left > 0 do
			task.wait()
		end
	end
	return merge(t, queue[key])
end
function StatsStore.read(key)
	return readFrom(store, pending, key)
end
function StatsStore.readShared(key)
	return readFrom(shared, pendingShared, key)
end

local function flushInto(into, queue)
	if not into then
		return -- (Studio: kept here, so /stats can show what a test did)
	end
	local batch = table.clone(queue)
	table.clear(queue)
	for key, p in batch do
		local saved = pcall(into.UpdateAsync, into, shardKey(key, SHARD), function(old)
			return merge(if typeof(old) == "table" then old else {}, p)
		end)
		if not saved then -- (next time)
			queue[key] = merge(queue[key] or {}, p)
		end
	end
end
local function flush()
	flushInto(store, pending)
	flushInto(shared, pendingShared)
end

task.spawn(function()
	local rng = Random.new()
	while true do
		task.wait(FLUSH + rng:NextNumber(-JITTER, JITTER))
		flush()
	end
end)
-- Shutting down: a publish closes every server at once, all flushing together, so a
-- throttled flush gets two more tries (Roblox allows up to 30 s here).
game:BindToClose(function()
	for attempt = 1, 3 do
		flush()
		if next(pending) == nil and next(pendingShared) == nil then
			return
		end
		task.wait(7)
	end
end)

return StatsStore
