-- Lasso training (Config.Training; the dummy and the throws are Training.client):
-- each catch the client reports (TrainLasso) adds TrainingSpot.perCatch (more for each pen level) to the player's "Lasso"
-- attribute, their lasso strength, which Gold.server saves with their gold. Only
-- counted from near their own pen's dummy (TrainingSpot), and no faster than the
-- throw itself takes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TrainingSpot = require(ReplicatedStorage.Shared.TrainingSpot)

local training = Config.Training
local CYCLE = training.Swing + training.Throw + training.Pull + training.Rest
local SLACK = 22 -- studs past Radius (lag; the bigger biomes' dummies stand further out than TrainingSpot's default)

local trainLasso = Instance.new("RemoteEvent")
trainLasso.Name = "TrainLasso"
trainLasso.Parent = ReplicatedStorage

local last = {} -- [player] = os.clock() of their last counted catch

trainLasso.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now - (last[player] or 0) < CYCLE * 0.8 / TrainingSpot.speed(player:GetAttribute("Lasso")) then
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local index = player:GetAttribute("Pen")
	local pen = index and workspace.Pens:FindFirstChild("Pen" .. index)
	local spot = pen and TrainingSpot.of(pen)
	if not hrp or not spot or ((hrp.Position - spot.Position) * Vector3.new(1, 0, 1)).Magnitude > training.Radius + SLACK then
		return
	end
	last[player] = now
	player:SetAttribute("Lasso", (player:GetAttribute("Lasso") or 0) + TrainingSpot.perCatch(player:GetAttribute("PenLevel")))
end)

Players.PlayerRemoving:Connect(function(player)
	last[player] = nil
end)
