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

-- Catches can come several to a throw once you're quick (Config.Training.MinCycle):
-- each player has a budget of them, filling at their speed (a little over, for lag)
-- and capped at a few throws' worth, and a report only counts what's in it.
local budget = {} -- [player] = catches they can still report
local last = {} -- [player] = os.clock() the budget was last topped up

trainLasso.OnServerEvent:Connect(function(player, n)
	n = math.floor(tonumber(n) or 1)
	if n < 1 or n ~= n then
		return
	end
	local now = os.clock()
	local speed = TrainingSpot.speed(player:GetAttribute("Lasso"))
	local perThrow = speed / math.min(speed, CYCLE / training.MinCycle)
	budget[player] = math.min((budget[player] or 1) + (now - (last[player] or now)) * speed / CYCLE * 1.25, math.max(3 * perThrow, 2))
	last[player] = now
	n = math.min(n, math.floor(budget[player]))
	if n < 1 then
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
	budget[player] -= n
	player:SetAttribute("Lasso", (player:GetAttribute("Lasso") or 0) + n * TrainingSpot.perCatch(player:GetAttribute("PenLevel")))
end)

Players.PlayerRemoving:Connect(function(player)
	last[player], budget[player] = nil, nil
end)
