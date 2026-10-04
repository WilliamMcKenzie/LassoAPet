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

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Gold")
if not ok then
	store = nil
end

local loaded = {} -- players whose saved gold has loaded, so a failed load never overwrites it
local ready = {} -- players whose load is over (loaded or not)
local bought = {} -- [player] = how much bought gold is already in their gold

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

local function save(player)
	if not store or not loaded[player] then
		return
	end
	local gold = player:GetAttribute("Gold") or 0
	for attempt = 1, 3 do
		if pcall(store.SetAsync, store, key(player), { gold = gold, bought = bought[player] or 0 }) then
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
	loaded[player], ready[player], bought[player] = nil, nil, nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	task.wait(2)
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
