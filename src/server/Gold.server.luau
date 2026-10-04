-- Each player's gold: the account total, saved between visits. It lives in
-- the player's "Gold" attribute, which the HUD shows. A ride's cash is added
-- when the rider gets home (BankCoins). Saving needs API access in Studio;
-- without it everyone starts at 0 and nothing is kept.
-- Gold bought with Robux (the "BoughtGold" attribute, Shop.server's running
-- total) is added once: the save keeps how much of it is in (bought), and only
-- the rest is added, saved straight away.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MAX_PER_RIDE = 100000 -- ignore anything bigger than a ride could earn
local Config = require(ReplicatedStorage.Shared.Config)

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Gold")
if not ok then
	store = nil
end

local loaded = {} -- players whose saved gold has loaded, so a failed load never overwrites it
local ready = {} -- players whose load is over (loaded or not)
local bought = {} -- [player] = how much bought gold is already in their gold
local savedAs = {} -- [player] = the gold and bought last saved (autosave skips it if they haven't changed)

local function key(player)
	return "u" .. player.UserId
end

local function load(player)
	player:SetAttribute("Gold", 0)
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
	local as = gold .. "/" .. (bought[player] or 0)
	if onlyIfChanged and savedAs[player] == as then
		return
	end
	for attempt = 1, 3 do
		if pcall(store.SetAsync, store, key(player), { gold = gold, bought = bought[player] or 0 }) then
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
end
Players.PlayerAdded:Connect(join)
for _, player in Players:GetPlayers() do
	task.spawn(join, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player], ready[player], bought[player], savedAs[player] = nil, nil, nil, nil
end)

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

local bankCoins = Instance.new("RemoteEvent")
bankCoins.Name = "BankCoins"
bankCoins.Parent = ReplicatedStorage

bankCoins.OnServerEvent:Connect(function(player, amount)
	if typeof(amount) ~= "number" or amount ~= amount or amount <= 0 or amount > MAX_PER_RIDE then
		return
	end
	player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + math.floor(amount))
end)
