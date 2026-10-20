-- Robux purchases (developer products).
-- Continue (Config.ContinueTiers): on the fail screen after a crash, the
-- ContinueRide remote asks for the purchase of the band for how far from home
-- the rider got (metres, from the client); once it's paid for, the same remote
-- tells the rider's client to pick the ride up where it ended (Ride.client), and
-- false if the purchase was cancelled. Until a band's product exists (id 0)
-- Studio gives it away for testing and live games don't offer it.
-- The shop (Config.Shop): the BuyShop remote asks for the purchase of one offer
-- by its Key, the same way. Paid, it goes into the purchase ledger (below) and
-- ShopGrant tells the client. Spawn Loong starts the Loong's exclusive event at
-- once (Events.server, as "/event loong" does), for the whole server.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Telemetry = require(script.Parent.Telemetry) -- (/stats: purchases)

local continueRide = Instance.new("RemoteEvent")
continueRide.Name = "ContinueRide"
continueRide.Parent = ReplicatedStorage

-- The band for `metres` from home: the furthest one passed.
local function continueTier(metres)
	local tier = Config.ContinueTiers[1]
	for _, t in Config.ContinueTiers do
		if (tonumber(metres) or 0) >= t.From then
			tier = t
		end
	end
	return tier
end

local isContinue = {} -- [product id] = true
for _, t in Config.ContinueTiers do
	if t.ProductId ~= 0 then
		isContinue[t.ProductId] = true
	end
	for _, id in t.OldProductIds or {} do
		isContinue[id] = true
	end
end

continueRide.OnServerEvent:Connect(function(player, metres)
	local id = continueTier(metres).ProductId
	if id ~= 0 then
		MarketplaceService:PromptProductPurchase(player, id)
		Telemetry.monoPrompt(player, "product:" .. id, "revive")
	elseif RunService:IsStudio() then
		continueRide:FireClient(player, true)
	end
end)

local shopGrant = Instance.new("RemoteEvent")
shopGrant.Name = "ShopGrant"
shopGrant.Parent = ReplicatedStorage
local buyShop = Instance.new("RemoteEvent")
buyShop.Name = "BuyShop"
buyShop.Parent = ReplicatedStorage

local offers, offerOf = {}, {} -- [Key] = offer; [product id] = offer
for _, list in { Config.Shop.Gold, Config.Shop.CashPacks, Config.Shop.Specials, Config.Shop.HalloweenPacks } do
	for _, offer in list do
		offers[offer.Key] = offer
		if offer.ProductId ~= 0 then
			offerOf[offer.ProductId] = offer
		end
		for _, id in offer.OldProductIds or {} do -- (a product it was sold as before: still granted)
			offerOf[id] = offer
		end
	end
end

local isHatch = {} -- [product id] = true: the paid hatch's tiers (Config.SpeedupEgg.Tiers)
for _, tier in Config.SpeedupEgg.Tiers do
	offerOf[tier.ProductId] = { Key = "SpeedupEgg" }
	isHatch[tier.ProductId] = true
end
local petOfferOf = {} -- [Key] = the Config.PetOffers entry
for _, pet in Config.PetOffers do
	petOfferOf[pet.Kind] = pet
	offers[pet.Kind] = { Key = pet.Kind, ProductId = pet.ProductId }
	if pet.ProductId ~= 0 then
		offerOf[pet.ProductId] = { Key = pet.Kind } -- (World 1's base stands: Client/LoongOffer)
	end
end

-- Paid random items (the Legendary Pet, and egg rolls now gold can be bought) are
-- never sold where the player's policy restricts them. Unknown counts as restricted.
local policies = {} -- [player] = restricted
local function randomRestricted(player)
	if policies[player] == nil then
		local ok, info = pcall(function()
			return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(player)
		end)
		policies[player] = not ok or info.ArePaidRandomItemsRestricted == true
	end
	return policies[player]
end
local restrictedCheck = Instance.new("BindableFunction") -- for Hatchery's RollGacha
restrictedCheck.Name = "RandomRestricted"
restrictedCheck.OnInvoke = randomRestricted
restrictedCheck.Parent = game:GetService("ServerStorage")

-- The purchase ledger, one DataStore entry per player, written in one UpdateAsync
-- per receipt so each purchase is recorded exactly once: the receipt ids seen
-- (the last 200), and running totals of what was bought: Gold (gold), Legendary
-- pets, Giant Horse eggs (giantEggs; giant: rides, as it was sold before) and Nukes,
-- plus how many rides and Nukes were used.
-- A receipt is only acknowledged once it's in the ledger. The ledger's totals go
-- onto the player as attributes, and the rest is handed over from them:
--   BoughtGold, BoughtPets, BoughtGiantEggs: Gold.server and Hatchery add what they haven't yet
--     (each saving how much it has, in its own entry, with the gold or pets).
--   GiantRides, Nukes: what's left to use; UseGiant / UseNuke spend one.
-- Without DataStores (Studio without API access) the ledger lives in memory.
local okStore, ledgerStore = pcall(function()
	return game:GetService("DataStoreService"):GetDataStore("Purchases")
end)
if not okStore then
	ledgerStore = nil
end
local ledgers = {} -- [player] = the ledger as last read or written
local MAX_RECEIPTS = 200

local function blank()
	return { receipts = {}, gold = 0, pets = 0, giant = 0, giantUsed = 0, giantEggs = 0, nukes = 0, nukesUsed = 0, hatches = 0, loongs = 0 }
end

local function show(player, ledger)
	ledgers[player] = ledger
	player:SetAttribute("BoughtHatches", ledger.hatches or 0)
	player:SetAttribute("BoughtGold", ledger.gold)
	player:SetAttribute("BoughtPets", ledger.pets)
	player:SetAttribute("BoughtHalloweenPets", ledger.halloweenPets or 0)
	player:SetAttribute("BoughtGiantEggs", ledger.giantEggs)
	for _, pet in Config.PetOffers do
		player:SetAttribute("Bought" .. pet.Kind .. "s", ledger[pet.Ledger] or 0)
	end
	local rides, nukes = ledger.giant - ledger.giantUsed, ledger.nukes - ledger.nukesUsed
	player:SetAttribute("GiantRides", if rides > 0 then rides else nil)
	player:SetAttribute("Nukes", if nukes > 0 then nukes else nil)
end

-- Changes the player's ledger with change(ledger) (which returns false to leave it
-- as it is); the new ledger, or nil if it couldn't be saved.
local function update(userId, change)
	local result
	if not ledgerStore then
		local player = Players:GetPlayerByUserId(userId)
		local ledger = player and ledgers[player] or blank()
		change(ledger)
		return ledger
	end
	local ok = pcall(function()
		ledgerStore:UpdateAsync("u" .. userId, function(old)
			local ledger = blank()
			if typeof(old) == "table" then
				for k, v in old do
					ledger[k] = v
				end
			end
			if change(ledger) == false then
				result = ledger
				return nil -- nothing to write
			end
			result = ledger
			return ledger
		end)
	end)
	return if ok then result else nil
end

Players.PlayerAdded:Connect(function(player)
	for attempt = 1, 3 do
		local ledger = update(player.UserId, function()
			return false
		end)
		if ledger then
			if player.Parent then
				show(player, ledger)
			end
			break
		end
		task.wait(attempt * 2)
	end
	if player.Parent and player:GetAttribute("GiantRides") then
		shopGrant:FireClient(player, "GiantHorse") -- bought before but not ridden yet
	end
end)
Players.PlayerRemoving:Connect(function(player)
	ledgers[player], policies[player] = nil, nil
end)

-- Records `offer` bought with receipt `purchaseId` (once). True once it's saved.
local petSold
-- The base stands' stock (Config.PetOffers: Stock each): sales counted in a DataStore key every
-- server shares (UpdateAsync, so two can't both take the last), what's left on workspace's
-- "<Kind>Left" for Client/LoongOffer, read again every STOCK_REFRESH seconds. No count saved
-- yet means StartLeft are left (QM: "to make it feel like its selling").
local STOCK_REFRESH = 10
local okStock, stockStore = pcall(function()
	return game:GetService("DataStoreService"):GetDataStore("LoongStock")
end)
if not okStock or RunService:IsStudio() then
	stockStore = nil
end
local function showLeft(pet, sold)
	local start = pet.Stock - (pet.StartLeft or pet.Stock)
	if typeof(sold) == "table" then sold = sold.sold end
	workspace:SetAttribute(pet.Kind .. "Left", math.max(0, pet.Stock - (tonumber(sold) or start)))
end
petSold = function(pet, purchaseId)
	local start = pet.Stock - (pet.StartLeft or pet.Stock)
	if not stockStore then
		showLeft(pet, (pet.Stock - (workspace:GetAttribute(pet.Kind .. "Left") or pet.Stock)) + 1)
		return true
	end
	return pcall(function()
		showLeft(pet, stockStore:UpdateAsync(pet.StockKey, function(n)
			local stock = if typeof(n) == "table" then n else { sold = tonumber(n) or start, receipts = {} }
			stock.receipts = stock.receipts or {}
			if not stock.receipts[purchaseId] then
				stock.sold += 1
				stock.receipts[purchaseId] = true
			end
			return stock
		end))
	end)
end
if Config.Podium.Hidden and Config.PetOffersLimited then
	for _, pet in Config.PetOffers do
		showLeft(pet, nil)
	end
	task.spawn(function()
		while true do
			for _, pet in Config.PetOffers do
				if stockStore then
					local ok, sold = pcall(stockStore.GetAsync, stockStore, pet.StockKey)
					if ok then
						showLeft(pet, sold)
					end
				end
			end
			task.wait(STOCK_REFRESH)
		end
	end)
end

local function record(userId, purchaseId, offer)
	local fresh = false
	local ledger = update(userId, function(ledger)
		fresh = false
		if table.find(ledger.receipts, purchaseId) then
			return false -- already recorded: it was handed over then
		end
		fresh = true
		table.insert(ledger.receipts, purchaseId)
		while #ledger.receipts > MAX_RECEIPTS do
			table.remove(ledger.receipts, 1)
		end
		if offer.Gold then
			ledger.gold += offer.Gold
		elseif offer.Count then
			ledger.halloweenPets = (ledger.halloweenPets or 0) + offer.Count
		elseif offer.Key == "Legendary" then
			ledger.pets += 1
		elseif offer.Key == "GiantHorse" then
			ledger.giantEggs += 1 -- a Giant Horse egg (QM, Oct 4: no longer a ride)
		elseif offer.Key == "SpeedupEgg" then
			ledger.hatches = (ledger.hatches or 0) + 1
		elseif offer.Key == "Nuke" then
			ledger.nukes += 1
		elseif petOfferOf[offer.Key] then
			local field = petOfferOf[offer.Key].Ledger
			ledger[field] = (ledger[field] or 0) + 1 -- a Loong (or Robo Shark) into your pen (Config.PetOffers)
		end
		return true
	end)
	if ledger and petOfferOf[offer.Key] and Config.PetOffersLimited then
		if not petSold(petOfferOf[offer.Key], purchaseId) then
			return false -- retry the receipt until its stock update is saved too
		end
	end
	if ledger and fresh and offer.Key == "SpawnLoong" then
		workspace.World:SetAttribute("ForceEventNow", true) -- (bought: no countdown)
		workspace.World:SetAttribute("ForceEvent", "Loong")
	end
	local player = Players:GetPlayerByUserId(userId)
	if ledger and player then
		show(player, ledger)
		if offer.Key ~= "SpeedupEgg" then
			shopGrant:FireClient(player, if offer.Key == "GiantHorse" then "GiantEgg" else offer.Key) -- ("GiantHorse" starts a giant ride: old purchases)
		end
	end
	return ledger ~= nil
end

-- Only one egg checkout at a time, so its selected target cannot be replaced.
local hatchPending = {}
local speedupEgg = Instance.new("RemoteEvent")
speedupEgg.Name = "SpeedupEgg"
speedupEgg.OnServerEvent:Connect(function(player, id)
	if hatchPending[player] or typeof(id) ~= "string" then
		return
	end
	local prepare = game:GetService("ServerStorage"):FindFirstChild("PrepareEggSpeedup")
	if not prepare then
		return
	end
	hatchPending[player] = true
	local ok, action, secondsLeft = pcall(prepare.Invoke, prepare, player, id)
	if not ok or action ~= "purchase" then
		hatchPending[player] = nil
		return
	end
	local productId = Config.speedupTier(secondsLeft or 0).ProductId
	local prompted = pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, productId)
	if prompted then
		Telemetry.monoPrompt(player, "product:" .. productId, "eggSpeedup")
	else
		hatchPending[player] = nil
	end
end)
speedupEgg.Parent = ReplicatedStorage
Players.PlayerRemoving:Connect(function(player)
	hatchPending[player] = nil
end)

-- The away panel's rainbow button (Config.AwayBoost, Client/Away): its product, or free in
-- Studio till it has one. Hatchery's BankAway banks the away gold Multiplier times over.
local awayGranted = {} -- [PurchaseId] = true (a receipt seen again is already banked)
local function bankAway(player)
	local bank = game:GetService("ServerStorage"):FindFirstChild("BankAway")
	return bank ~= nil and bank:Invoke(player, Config.AwayBoost.Multiplier) == true
end
buyShop.OnServerEvent:Connect(function(player, key, source)
	if key == "Away4x" then
		local id = Config.AwayBoost.ProductId
		if id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, id)
			Telemetry.monoPrompt(player, "product:" .. id, "away4x")
		elseif RunService:IsStudio() then
			bankAway(player)
		end
		return
	end
	local offer = typeof(key) == "string" and offers[key]
	if not offer or ((offer.Key == "Legendary" or offer.Count) and randomRestricted(player)) then
		return
	end
	if Config.PetOffersLimited and petOfferOf[key] and (workspace:GetAttribute(key .. "Left") or 0) <= 0 then
		return
	end
	if offer.Count and offer.ProductId == 0 then return end -- not on sale until configured
	if offer.ProductId ~= 0 then
		MarketplaceService:PromptProductPurchase(player, offer.ProductId)
		local surface = if petOfferOf[key] then "limited_" .. key elseif source == "shop" then "shop_" .. offer.Key elseif offer.Gold then "cashShortfall" else nil -- (each shop item its own /stats row: SimpleStats)
		Telemetry.monoPrompt(player, "product:" .. offer.ProductId, surface)
	elseif RunService:IsStudio() then
		record(player.UserId, game:GetService("HttpService"):GenerateGUID(false), offer)
	end
end)

-- Spends one Giant Horse ride or Nuke (Ride.client, as the ride starts): true if
-- there was one to spend.
local function spender(name, bought, used)
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.OnServerInvoke = function(player)
		local spent = false
		local ledger = update(player.UserId, function(ledger)
			if ledger[bought] - ledger[used] < 1 then
				return false
			end
			ledger[used] += 1
			spent = true
			return true
		end)
		if ledger then
			show(player, ledger)
		end
		return spent and ledger ~= nil
	end
	remote.Parent = ReplicatedStorage
end
spender("UseGiant", "giant", "giantUsed")
spender("UseNuke", "nukes", "nukesUsed")

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	local player = Players:GetPlayerByUserId(userId)
	if player and isHatch[productId] and not purchased then
		hatchPending[player] = nil
	end
	if player and isContinue[productId] and not purchased then
		continueRide:FireClient(player, false)
	end
	if player and not purchased then
		Telemetry.monoCancel(player, "product:" .. productId) -- (/stats: closed without buying)
	end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	if receipt.ProductId == Config.AwayBoost.ProductId and receipt.ProductId ~= 0 then
		-- (the away panel's 4x: banked while they're here with away gold to bank; else tried again,
		-- as Roblox does on their next visit, when it's there again)
		if awayGranted[receipt.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if player and bankAway(player) then
			awayGranted[receipt.PurchaseId] = true
			Telemetry.purchase(player, receipt.CurrencySpent, "product:" .. receipt.ProductId)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Shop offers go into the ledger whether or not the buyer is still here.
	local offer = offerOf[receipt.ProductId]
	if offer then
		local granted = record(receipt.PlayerId, receipt.PurchaseId, offer)
		local buyer = Players:GetPlayerByUserId(receipt.PlayerId)
		if granted == true then
			Telemetry.purchase(buyer, receipt.CurrencySpent, "product:" .. receipt.ProductId) -- (/stats: % who bought)
		end
		if granted and isHatch[receipt.ProductId] then
			local player = Players:GetPlayerByUserId(receipt.PlayerId)
			if player then hatchPending[player] = nil end
		end
		return if granted then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if player and isContinue[receipt.ProductId] then
		Telemetry.purchase(player, receipt.CurrencySpent, "product:" .. receipt.ProductId)
		continueRide:FireClient(player, true)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
