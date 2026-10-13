-- Our own cross-server totals (QM, Oct 13: Analytics V1): counts added here by any server
-- script go into this world's SessionStats DataStore under a key, merged into what's
-- there about every FLUSH seconds (UpdateAsync, so servers never overwrite each other),
-- plus whatever this server hasn't sent yet when it's read. Totals only: no player ids.
-- Nothing is kept in Studio (testing would skew it): there the adds just print.
--
--   StatsStore.add(key, { field = n, ... })   -- n added to each field
--   StatsStore.read(key) -> { field = n }      -- the store's plus this server's pending
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local FLUSH = 60

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("SessionStats"))
if not ok or RunService:IsStudio() then
	store = nil
end

local StatsStore = {}
local pending = {} -- [key] = { field = n }

local function merge(into, from)
	for f, n in from or {} do
		if type(n) == "number" then
			into[f] = (into[f] or 0) + n
		end
	end
	return into
end

function StatsStore.add(key, fields)
	if RunService:IsStudio() then
		local list = {}
		for f, n in fields do
			table.insert(list, f .. " +" .. n)
		end
		print("[Stats] " .. key .. ": " .. table.concat(list, ", "))
	end
	pending[key] = merge(pending[key] or {}, fields)
end

function StatsStore.read(key)
	local t = {}
	if store then
		local got, data = pcall(store.GetAsync, store, key)
		if got and typeof(data) == "table" then
			merge(t, data)
		end
	end
	return merge(t, pending[key])
end

local function flush()
	if not store then
		pending = {}
		return
	end
	local batch = pending
	pending = {}
	for key, p in batch do
		local saved = pcall(store.UpdateAsync, store, key, function(old)
			return merge(if typeof(old) == "table" then old else {}, p)
		end)
		if not saved then -- (next time)
			pending[key] = merge(pending[key] or {}, p)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(FLUSH)
		flush()
	end
end)
game:BindToClose(flush)

return StatsStore
