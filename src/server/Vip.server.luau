-- VIP (game pass, Config.Passes): a gold trail behind you, on foot and riding
-- (a rider's character sits on their pet on every screen, so it follows the ride).
-- The gold fence and banners are PenLevel.server's, the gold name Pens.server's.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
require(script.Parent.Passes)

local function trail(player, character)
	local hrp = character and character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	for _, name in { "VipTrail", "VipTrailTop", "VipTrailBottom" } do
		local old = hrp:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	if not player:GetAttribute("PassVIP") then
		return
	end
	local top, bottom = Instance.new("Attachment"), Instance.new("Attachment")
	top.Name, bottom.Name = "VipTrailTop", "VipTrailBottom"
	top.Position, bottom.Position = Vector3.new(0, 0.8, 0), Vector3.new(0, -1.2, 0)
	top.Parent, bottom.Parent = hrp, hrp
	local t = Instance.new("Trail")
	t.Name = "VipTrail"
	t.Attachment0, t.Attachment1 = top, bottom
	t.Color = ColorSequence.new(Config.Vip.Trail[1], Config.Vip.Trail[2])
	t.Transparency = NumberSequence.new(0.1, 1)
	t.Lifetime = 0.5
	t.MinLength = 0.2
	t.LightEmission = 0.6
	t.FaceCamera = true
	t.Parent = hrp
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
