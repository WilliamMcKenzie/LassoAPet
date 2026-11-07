-- Each player's gold: the account total, saved between visits. It lives in
-- the player's "Gold" attribute, which the HUD shows. A ride's cash is added
-- when the rider gets home (BankCoins), counted here, not by the client (QM, Oct 4:
-- server authoritative): see "Ride cash" below. Saving needs API access in Studio;
-- without it everyone starts at 0 and nothing is kept.
-- Gold bought with Robux (the "BoughtGold" attribute, Shop.server's running
-- total) is added once: the save keeps how much of it is in (bought), and only
-- the rest is added, saved straight away.
-- (The old stamina level, `stamina`: no more stamina since Oct 10 (QM), so it's no longer
-- used, only written back as it was loaded.)
-- And the biome barriers you've broken (the "GatesBroken" attribute, the last biome
-- whose barrier you rode through: Gate.client's BreakGate), as `gates` (QM, Oct 9).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MAX_PER_RIDE = 100000 -- ignore anything bigger than a ride could earn
local Config = require(ReplicatedStorage.Shared.Config)
require(script.Parent.Passes) -- (PassDoubleGold: x2 ride cash, below)
local Funnel = require(script.Parent.Funnel)
local Telemetry = require(script.Parent.Telemetry)

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Gold")
if not ok then
	store = nil
end

local loaded = {} -- players whose saved gold has loaded, so a failed load never overwrites it
local ready = {} -- players whose load is over (loaded or not)
local bought = {} -- [player] = how much bought gold is already in their gold
local savedAs = {} -- [player] = the gold and bought last saved (autosave skips it if they haven't changed)
local oldStamina = {} -- [player] = the save's old stamina level, kept as it was

-- Gold is shared by every world (QM, Oct 13); the barriers you've broken are each
-- world's own: `gates` in World 1, `gates2` in World 2... The save keeps the other
-- worlds' as it found them.
local GATES = if Config.World == 1 then "gates" else "gates" .. Config.World
local others = {} -- [player] = the loaded record, for the other worlds' fields
-- How long you've played this world, all visits (`played`, `played2`...; QM, Oct 13: /stats'
-- time to unlock each biome). `playedFull` marks a record that's counted it from its very
-- first visit (records from before this only count from here on, so /stats skips them).
local PLAYED = if Config.World == 1 then "played" else "played" .. Config.World
local playedBase, playedFrom, playedFull = {}, {}, {} -- [player] = seconds at join, os.time() at join, counted from the start
local function playedNow(player)
	return (playedBase[player] or 0) + (if playedFrom[player] then os.time() - playedFrom[player] else 0)
end

local function key(player)
	return "u" .. player.UserId
end

local function load(player)
	player:SetAttribute("Gold", 0)
	player:SetAttribute("GatesBroken", 1) -- (the last biome whose barrier you've ridden through: Gate.client; 1 = none yet)
	if not store then
		return
	end
	for attempt = 1, 3 do
		local success, value = pcall(store.GetAsync, store, key(player))
		if success then
			if player.Parent then
				-- (saved as a number before the shop: no bought gold in it)
				local gold = if typeof(value) == "table" then value.gold else value
				bought[player] = if typeof(value) == "table" then tonumber(value.bought) or 0 else 0
				player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + (tonumber(gold) or 0))
				oldStamina[player] = if typeof(value) == "table" then tonumber(value.stamina) else nil
				others[player] = if typeof(value) == "table" then value else nil
				playedBase[player] = if typeof(value) == "table" then tonumber(value[PLAYED]) or 0 else 0
				playedFrom[player] = os.time()
				playedFull[player] = value == nil or (typeof(value) == "table" and value[PLAYED .. "Full"] == true)
				local gates = if typeof(value) == "table" then tonumber(value[GATES]) else nil
				player:SetAttribute("FinishTrail", if typeof(value) == "table" then tonumber(value.trail) else nil) -- (the finish line's trails: Config.FinishTrails, shared by every world)
				player:SetAttribute("Rebirths", if typeof(value) == "table" then tonumber(value.rebirths) else nil) -- (Config.Rebirth, shared by every world)
				player:SetAttribute("TrailsOwned", if typeof(value) == "table" then tonumber(value.trails) else nil) -- (Config.TrailBars, shared by every world)
				player:SetAttribute("Reborn", if typeof(value) == "table" then tonumber(value.reborn) else nil) -- (Config.Luck: rebirths, Hatchery's Rebirth)
				player:SetAttribute("LuckBonus", if typeof(value) == "table" then tonumber(value.luck) else nil) -- (Config.Luck: the goals' luck, Hatchery's ClaimQuest)
				player:SetAttribute("OwnsSlingshot", if typeof(value) == "table" and value.slingshot == true then true else nil) -- (Config.Slingshot)
				player:SetAttribute("GatesBroken", math.max(player:GetAttribute("GatesBroken") or 1, gates or 1))
				if typeof(value) == "table" and value.v1new then -- (Analytics V1: a new World 1 player since V1)
					player:SetAttribute("V1New", true)
				end
				for _, world in typeof(value) == "table" and typeof(value.worlds) == "table" and value.worlds or {} do
					if tonumber(world) then
						player:SetAttribute("OwnsWorld" .. world, true) -- (the Worlds menu: Travel, not Buy)
					end
				end
				loaded[player] = true
			end
			return
		end
		if attempt == 3 or RunService:IsStudio() then
			break -- no API access in Studio fails every time: don't keep the player waiting
		end
		task.wait(attempt * 2)
	end
end

-- onlyIfChanged: the autosave's, which skips it when nothing changed.
local function save(player, onlyIfChanged)
	if not store or not loaded[player] then
		return
	end
	local gold = player:GetAttribute("Gold") or 0
	local gates = player:GetAttribute("GatesBroken") or 1
	local worlds = {} -- (the worlds bought, shared by them all)
	for world in Config.Places do
		if player:GetAttribute("OwnsWorld" .. world) then
			table.insert(worlds, world)
		end
	end
	local trail = player:GetAttribute("FinishTrail")
	local rebirths = player:GetAttribute("Rebirths")
	local trails = player:GetAttribute("TrailsOwned")
	local slingshot = player:GetAttribute("OwnsSlingshot") == true
	local reborn = player:GetAttribute("Reborn")
	local luck = player:GetAttribute("LuckBonus")
	local as = gold .. "/" .. (bought[player] or 0) .. "/" .. gates .. "/" .. table.concat(worlds, ",") .. "/" .. tostring(trail) .. "/" .. tostring(rebirths) .. "/" .. tostring(trails) .. "/" .. tostring(slingshot) .. "/" .. tostring(reborn) .. "/" .. tostring(luck)
	if onlyIfChanged and savedAs[player] == as then
		return
	end
	for attempt = 1, 3 do
		local record = table.clone(others[player] or {})
		record.gold, record.bought, record.stamina, record[GATES] = gold, bought[player] or 0, oldStamina[player], gates
		record.worlds = if #worlds > 0 then worlds else nil
		record.trail = trail
		record.rebirths = rebirths
		record.trails = trails
		record.slingshot = slingshot or nil
		record.reborn = reborn
		record.luck = luck
		record.v1new = player:GetAttribute("V1New") or record.v1new
		record.lastWorld = Config.World -- (where you were last: a join from the home page goes back there)
		record[PLAYED] = math.floor(playedNow(player))
		record[PLAYED .. "Full"] = playedFull[player] or nil
		if pcall(store.SetAsync, store, key(player), record) then
			savedAs[player] = as
			return
		end
		task.wait(attempt)
	end
end

-- Adds bought gold not yet in, and saves at once.
local function addBought(player)
	local total = player:GetAttribute("BoughtGold")
	if not ready[player] or not total or total <= (bought[player] or 0) then
		return
	end
	player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + total - (bought[player] or 0))
	Telemetry.gold(player, "purchased", total - (bought[player] or 0))
	Funnel.cash(player, false, total - (bought[player] or 0), Enum.AnalyticsEconomyTransactionType.IAP.Name, "Cash Pack")
	bought[player] = total
	save(player)
end

local function join(player)
	load(player)
	ready[player] = true
	player:GetAttributeChangedSignal("BoughtGold"):Connect(function()
		addBought(player)
	end)
	addBought(player)
	player:SetAttribute("GoldLoaded", true) -- (the saved gold's in: reward popups count from here, Client/RewardPopups)
end
Players.PlayerAdded:Connect(join)
for _, player in Players:GetPlayers() do
	task.spawn(join, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player], ready[player], bought[player], savedAs[player], oldStamina[player], others[player] = nil, nil, nil, nil, nil, nil
	playedBase[player], playedFrom[player], playedFull[player] = nil, nil, nil
end)

-- Worlds (QM, Oct 13): each its own Place. World 2 and the Worlds menu are gone for now (QM,
-- Nov 6): no BuyWorld or Travel; worlds already owned stay saved.
-- A world bought for Robux (Config.WorldProducts; Shop.server's receipt): false till the save's loaded.
local grantWorld = Instance.new("BindableFunction")
grantWorld.Name = "GrantWorld"
grantWorld.OnInvoke = function(player, world)
	if not loaded[player] then
		return false
	end
	if not player:GetAttribute("OwnsWorld" .. world) then
		player:SetAttribute("OwnsWorld" .. world, true)
		Funnel.boughtWorld(player, world)
		save(player)
	end
	return true
end
grantWorld.Parent = game:GetService("ServerStorage")
-- A world given some other way (the Starter Pack: Hatchery sets "OwnsWorld2"): saved at once.
local function watchWorlds(player)
	for world in Config.Places do
		if world ~= 1 then
			player:GetAttributeChangedSignal("OwnsWorld" .. world):Connect(function()
				if player:GetAttribute("OwnsWorld" .. world) and loaded[player] then
					save(player)
				end
			end)
		end
	end
end
Players.PlayerAdded:Connect(watchWorlds)
for _, player in Players:GetPlayers() do
	watchWorlds(player)
end
-- A rebirth (Hatchery's Rebirth: cash 0, "Reborn" + 1): saved at once.
local function watchReborn(player)
	for _, name in { "Reborn", "LuckBonus" } do -- (and luck from a goal)
		player:GetAttributeChangedSignal(name):Connect(function()
			if loaded[player] then
				save(player)
			end
		end)
	end
end
Players.PlayerAdded:Connect(watchReborn)
for _, player in Players:GetPlayers() do
	watchReborn(player)
end

-- BuyTrail (Config.TrailBars, QM Oct 15): with every world yours, the next trail for its gold.
local buyTrail = Instance.new("RemoteFunction")
buyTrail.Name = "BuyTrail"
buyTrail.OnServerInvoke = function(player)
	if not loaded[player] then
		return false
	end
	local i = Config.nextTrail(player)
	local price = i and Config.TrailBars[i].Price
	local gold = player:GetAttribute("Gold") or 0
	if not price or gold < price then
		return false
	end
	player:SetAttribute("Gold", gold - price)
	player:SetAttribute("TrailsOwned", bit32.bor(tonumber(player:GetAttribute("TrailsOwned")) or 0, bit32.lshift(1, i - 1)))
	save(player)
	return true
end
buyTrail.Parent = ReplicatedStorage

-- BuySlingshot (Config.Slingshot, QM Nov 6): the top bar's first goal, once, for its gold.
local buySlingshot = Instance.new("RemoteFunction")
buySlingshot.Name = "BuySlingshot"
buySlingshot.OnServerInvoke = function(player)
	local gold = player:GetAttribute("Gold") or 0
	if not loaded[player] or player:GetAttribute("OwnsSlingshot") or gold < Config.Slingshot.Price then
		return false
	end
	player:SetAttribute("Gold", gold - Config.Slingshot.Price)
	player:SetAttribute("OwnsSlingshot", true)
	save(player)
	return true
end
buySlingshot.Parent = ReplicatedStorage


-- "/reset" (Hatchery): gold, rebirths, trails, the worlds bought and every world's
-- barriers and played time gone, saved at once.
local hardReset = Instance.new("BindableEvent")
hardReset.Name = "HardReset"
hardReset.Event:Connect(function(player)
	player:SetAttribute("Gold", 0)
	player:SetAttribute("GatesBroken", 1)
	for _, name in { "Rebirths", "FinishTrail", "TrailsOwned", "Reborn", "LuckBonus" } do
		player:SetAttribute(name, nil)
	end
	for world in Config.Places do
		player:SetAttribute("OwnsWorld" .. world, nil)
	end
	local record = others[player]
	if record then
		for field in table.clone(record) do
			if type(field) == "string" and (field:match("^gates") or field:match("^played")) then
				record[field] = nil
			end
		end
	end
	playedBase[player], playedFrom[player], playedFull[player] = 0, os.time(), true
	save(player)
end)
hardReset.Parent = game:GetService("ServerStorage")

-- Autosave (QM, Oct 4): every Config.AutosaveEvery seconds each player's gold is saved
-- if it changed since it was last saved (so a server crash loses that much at most),
-- spread out over the interval to stay inside the DataStore budget. Shutting down
-- saves everyone and waits for the saves to finish (Roblox allows up to 30 s).
task.spawn(function()
	while true do
		local list = Players:GetPlayers()
		if #list == 0 then
			task.wait(Config.AutosaveEvery)
			continue
		end
		for _, player in list do
			task.wait(Config.AutosaveEvery / #list)
			if player.Parent then
				task.spawn(save, player, true)
			end
		end
	end
end)

game:BindToClose(function()
	local left = 0
	for _, player in Players:GetPlayers() do
		left += 1
		task.spawn(function()
			save(player)
			left -= 1
		end)
	end
	local deadline = os.clock() + 25
	while left > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

-- Seconds played so far (Funnel.unlocked's), nil if not known (an older save).
local playedTime = Instance.new("BindableFunction")
playedTime.Name = "PlayedTime"
playedTime.OnInvoke = function(player)
	return if playedFull[player] then playedNow(player) else nil
end
playedTime.Parent = game:GetService("ServerStorage")

-- Riding through a biome's barrier breaks it for good (Gate.client): only ever up.
local breakGate = Instance.new("RemoteEvent")
breakGate.Name = "BreakGate"
breakGate.Parent = ReplicatedStorage
breakGate.OnServerEvent:Connect(function(player, i)
	local broken = player:GetAttribute("GatesBroken") or 1
	if typeof(i) == "number" and i > broken and i <= #Config.Biomes then
		player:SetAttribute("GatesBroken", i)
		if playedFull[player] then -- (/stats: how long it took to get here, Stats.server)
			local unlocked = game:GetService("ServerStorage"):FindFirstChild("BiomeUnlocked")
			for b = broken + 1, i do
				if unlocked then
					unlocked:Fire(player, b, playedNow(player))
				end
			end
		end
		Funnel.reached(player, broken, i, if playedFull[player] then playedNow(player) else nil) -- (analytics: Zones Reached)
	end
end)

local bankCoins = Instance.new("RemoteEvent")
bankCoins.Name = "BankCoins"
bankCoins.Parent = ReplicatedStorage

-- Ride cash ------------------------------------------------------------------
-- A ride earns coins for every animal you lasso across onto (Config.LassoCoins, else
-- Config.RarityCoins by its rarity), as Ride.client counts them. The server keeps its
-- own count from the ride's cues (Riders.server's remotes): a "take" (you landed on
-- a stampede animal) while you were already riding, then the next sync's animal is
-- what you landed on. At most one every MIN_TAKE_GAP seconds.
-- BankCoins only says the ride's over: what's banked is the server's count (never
-- more than the client's, which can only be lower if it dropped coins). "end" (the
-- ride's over, after any banking) clears the count.
local Animals = ReplicatedStorage.Shared.Animals
local MIN_TAKE_GAP = 0.5
local rideCash = {} -- [player] = coins counted this ride
local riding = {} -- [player] = true once they've synced on an animal this ride
local pendingTake = {} -- [player] = os.clock() of a take not yet credited
local lastTake = {} -- [player] = os.clock() of the last credited take

local function coinsFor(kind)
	if Config.LassoCoins[kind] then
		return Config.LassoCoins[kind]
	end
	local module = Animals:FindFirstChild(kind)
	local ok, class = pcall(require, module)
	return ok and class and Config.RarityCoins[class.Rarity] or 0
end

ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
	if what == "take" then
		local now = os.clock()
		if riding[player] and now - (lastTake[player] or 0) >= MIN_TAKE_GAP then
			pendingTake[player] = now
		end
	elseif what == "end" then
		rideCash[player], riding[player], pendingTake[player] = nil, nil, nil
	end
end)

ReplicatedStorage:WaitForChild("RideSync").OnServerEvent:Connect(function(player, kind)
	if type(kind) ~= "string" or kind == "" or not Animals:FindFirstChild(kind) then
		return -- ("": between animals, lassoed across)
	end
	local taken = pendingTake[player]
	if taken and os.clock() - taken < 5 then
		pendingTake[player], lastTake[player] = nil, os.clock()
		rideCash[player] = (rideCash[player] or 0) + coinsFor(kind)
		local quests = game:GetService("ServerStorage"):FindFirstChild("QuestProgress") -- (Hatchery's: "Lasso animals")
		if quests then
			quests:Fire(player, "lasso", kind)
		end
	end
	riding[player] = true
end)

bankCoins.OnServerEvent:Connect(function(player, amount)
	if typeof(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return
	end
	local cash = math.min(rideCash[player] or 0, math.floor(amount), MAX_PER_RIDE)
	cash *= Config.goldX(player) -- x2 Gold (game pass) and rebirths (the HUD shows it multiplied as you ride)
	rideCash[player] = nil
	if cash > 0 then
		player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + cash)
		Telemetry.gold(player, "earned", cash)
		Funnel.cash(player, false, cash, Enum.AnalyticsEconomyTransactionType.Gameplay.Name, "Ride")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	rideCash[player], riding[player], pendingTake[player], lastTake[player] = nil, nil, nil, nil
end)
