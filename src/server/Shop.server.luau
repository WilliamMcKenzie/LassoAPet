-- Robux purchases (developer products).
-- Continue (Config.ContinueTiers): on the fail screen after a crash, the
-- ContinueRide remote asks for the purchase of the band for how far from home
-- the rider got (metres, from the client); once it's paid for, the same remote
-- tells the rider's client to pick the ride up where it ended (Ride.client), and
-- false if the purchase was cancelled. Until a band's product exists (id 0)
-- Studio gives it away for testing and live games don't offer it.

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
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
