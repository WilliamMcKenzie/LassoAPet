-- Lasso training (Config.Training; the dummy and the throws are Training.client):
-- each catch the client reports (TrainLasso) adds PerCatch to the player's "Lasso"
-- attribute, their lasso strength, which Gold.server saves with their gold. Only
-- counted from near the dummy, and no faster than the throw itself takes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local training = Config.Training
local CYCLE = training.Swing + training.Throw + training.Pull + training.Rest
local SLACK = 6 -- studs past Radius (lag, and the client checks first)

local trainLasso = Instance.new("RemoteEvent")
trainLasso.Name = "TrainLasso"
trainLasso.Parent = ReplicatedStorage

local last = {} -- [player] = os.clock() of their last counted catch

trainLasso.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now - (last[player] or 0) < CYCLE * 0.8 then
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp or ((hrp.Position - training.Position) * Vector3.new(1, 0, 1)).Magnitude > training.Radius + SLACK then
		return
	end
	last[player] = now
	player:SetAttribute("Lasso", (player:GetAttribute("Lasso") or 0) + training.PerCatch)
end)

Players.PlayerRemoving:Connect(function(player)
	last[player] = nil
end)
