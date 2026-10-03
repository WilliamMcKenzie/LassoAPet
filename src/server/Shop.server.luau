-- Robux purchases (developer products).
-- Continue (Config.ContinueProductId): on the fail screen after a crash, the
-- ContinueRide remote asks for the purchase; once it's paid for, the same remote
-- tells the rider's client to pick the ride up where it ended (Ride.client), and
-- false if the purchase was cancelled. Until the product exists (id 0) Studio
-- gives it away for testing and live games don't offer it.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local continueRide = Instance.new("RemoteEvent")
continueRide.Name = "ContinueRide"
continueRide.Parent = ReplicatedStorage

continueRide.OnServerEvent:Connect(function(player)
	local id = Config.ContinueProductId
	if id ~= 0 then
		MarketplaceService:PromptProductPurchase(player, id)
	elseif RunService:IsStudio() then
		continueRide:FireClient(player, true)
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	local player = Players:GetPlayerByUserId(userId)
	if player and productId == Config.ContinueProductId and not purchased then
		continueRide:FireClient(player, false)
	end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if receipt.ProductId == Config.ContinueProductId then
		continueRide:FireClient(player, true)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
