-- Your trail (QM, Oct 15: "a trail on the player as well as the animal"): the best one you own
-- (Config.trailColors: the trail bars, the finish line's old ones, the bought Rainbow Trail)
-- streams off your character too, on foot and riding, built like VIP's gold one
-- (Shared/RiderTrail), so everyone sees it. Your ride's own is Client/Ride's.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RiderTrail = require(ReplicatedStorage.Shared.RiderTrail)

local NAME = "OwnedTrail"

local function trail(player, character)
	local hrp = character and character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	local colors = Config.trailColors(player)
	if not colors then
		RiderTrail.remove(hrp, NAME)
		return
	end
	RiderTrail.make(hrp, NAME, colors, 0.5)
end

local function watch(player)
	player.CharacterAdded:Connect(function(character)
		trail(player, character)
	end)
	for _, name in { "TrailsOwned", "FinishTrail", "RainbowTrail" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			trail(player, player.Character)
		end)
	end
	if player.Character then
		task.spawn(trail, player, player.Character)
	end
end

Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	task.spawn(watch, player)
end
