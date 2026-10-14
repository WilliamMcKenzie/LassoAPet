-- VIP (game pass, Config.Passes): a gold trail behind you, on foot and riding
-- (a rider's character sits on their pet on every screen, so it follows the ride).
-- The gold fence and banners are PenLevel.server's, the gold name Pens.server's.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RiderTrail = require(ReplicatedStorage.Shared.RiderTrail)
require(script.Parent.Passes)

local function trail(player, character)
	local hrp = character and character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	if not player:GetAttribute("PassVIP") then
		RiderTrail.remove(hrp, "VipTrail")
		return
	end
	RiderTrail.make(hrp, "VipTrail", Config.Vip.Trail, 0.5) -- (Shared/RiderTrail: the sprint's white one is built the same way)
end

local function watch(player)
	player.CharacterAdded:Connect(function(character)
		trail(player, character)
	end)
	player:GetAttributeChangedSignal("PassVIP"):Connect(function()
		trail(player, player.Character)
	end)
	if player.Character then
		task.spawn(trail, player, player.Character)
	end
end

Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	task.spawn(watch, player)
end
