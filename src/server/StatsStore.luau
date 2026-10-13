-- Our own cross-server totals (QM, Oct 13: Analytics V1): counts added here by any server
-- script go into this world's SessionStats DataStore under a key, merged into what's
-- there about every FLUSH seconds (UpdateAsync, so servers never overwrite each other),
-- plus whatever this server hasn't sent yet when it's read. Totals only: no player ids.
-- Nothing is saved from Studio (testing would skew it): there the adds print and stay
-- in this server only.
--
--   StatsStore.add(key, { field = n, ... })   -- n added to each field ("max:" fields keep the biggest)
--   StatsStore.read(key) -> { field = n }      -- the store's plus this server's pending
--   StatsStore.addShared / readShared          -- the same, in the store every world shares
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local FLUSH = 60

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("SessionStats"))
if not ok or RunService:IsStudio() then
	store = nil
end
local okShared, shared = pcall(DataStoreService.GetDataStore, DataStoreService, "SessionStatsShared") -- (every world's)
if not okShared or RunService:IsStudio() then
	shared = nil
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

local function readFrom(from, queue, key)
	local t = {}
	if from then
		local got, data = pcall(from.GetAsync, from, key)
		if got and typeof(data) == "table" then
			merge(t, data)
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
		local saved = pcall(into.UpdateAsync, into, key, function(old)
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
	while true do
		task.wait(FLUSH)
		flush()
	end
end)
game:BindToClose(flush)

return StatsStore
