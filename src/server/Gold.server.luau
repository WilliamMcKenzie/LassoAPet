-- Each player's gold: the account total, saved between visits. It lives in
-- the player's "Gold" attribute, which the HUD shows. A ride's cash is added
-- when the rider gets home (BankCoins). Saving needs API access in Studio;
-- without it everyone starts at 0 and nothing is kept.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAX_PER_RIDE = 100000 -- ignore anything bigger than a ride could earn

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Gold")
if not ok then
	store = nil
end

local loaded = {} -- players whose saved gold has loaded, so a failed load never overwrites it

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
				player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + (tonumber(value) or 0))
				loaded[player] = true
			end
			return
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
		if pcall(store.SetAsync, store, key(player), gold) then
			return
		end
		task.wait(attempt)
	end
end

Players.PlayerAdded:Connect(load)
for _, player in Players:GetPlayers() do
	task.spawn(load, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player] = nil
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
