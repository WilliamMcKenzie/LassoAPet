-- Robux purchases (developer products).
-- Continue (Config.ContinueTiers): on the fail screen after a crash, the
-- ContinueRide remote asks for the purchase of the band for how far from home
-- the rider got (metres, from the client); once it's paid for, the same remote
-- tells the rider's client to pick the ride up where it ended (Ride.client), and
-- false if the purchase was cancelled. Until a band's product exists (id 0)
-- Studio gives it away for testing and live games don't offer it.
-- The shop (Config.Shop): the BuyShop remote asks for the purchase of one offer
-- by its Key, the same way (free in Studio until its product exists). Paid,
-- grant() hands it over: gold onto the account, a Giant Horse ride or a Legendary
-- pet (ShopGrant tells the client), or a Nuke for the next ride ("Nukes").

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

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
end

continueRide.OnServerEvent:Connect(function(player, metres)
	local id = continueTier(metres).ProductId
	if id ~= 0 then
		MarketplaceService:PromptProductPurchase(player, id)
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
for _, list in { Config.Shop.Gold, Config.Shop.Specials } do
	for _, offer in list do
		offers[offer.Key] = offer
		if offer.ProductId ~= 0 then
			offerOf[offer.ProductId] = offer
		end
	end
end

-- Hands a paid offer over. False if it can't be yet (no pen for the pet).
local function grant(player, offer)
	if offer.Gold then
		player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + offer.Gold)
	elseif offer.Key == "Nuke" then
		player:SetAttribute("Nukes", (player:GetAttribute("Nukes") or 0) + 1)
	elseif offer.Key == "Legendary" then
		local kind = game:GetService("ServerStorage"):WaitForChild("GrantPet"):Invoke(player)
		if not kind then
			return false
		end
		shopGrant:FireClient(player, "Legendary", kind)
		return true
	end
	shopGrant:FireClient(player, offer.Key)
	return true
end

buyShop.OnServerEvent:Connect(function(player, key)
	local offer = typeof(key) == "string" and offers[key]
	if not offer then
		return
	end
	if offer.ProductId ~= 0 then
		MarketplaceService:PromptProductPurchase(player, offer.ProductId)
	elseif RunService:IsStudio() then
		grant(player, offer)
	end
end)

-- The Nuke is spent when the ride it's for starts (Ride.client).
local useNuke = Instance.new("RemoteEvent")
useNuke.Name = "UseNuke"
useNuke.OnServerEvent:Connect(function(player)
	local n = (player:GetAttribute("Nukes") or 0) - 1
	player:SetAttribute("Nukes", if n > 0 then n else nil)
end)
useNuke.Parent = ReplicatedStorage

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	local player = Players:GetPlayerByUserId(userId)
	if player and isContinue[productId] and not purchased then
		continueRide:FireClient(player, false)
	end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if isContinue[receipt.ProductId] then
		continueRide:FireClient(player, true)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local offer = offerOf[receipt.ProductId]
	if offer and grant(player, offer) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
