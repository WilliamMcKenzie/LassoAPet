-- The 100x Luck Event's sign (Config.LuckEvent, QM Nov 7): rolls the rainbow along the title on
-- workspace.LuckEventSign's Board (Shared/LuckEventSign) and counts down under it: "Starts in:
-- m:ss", or "Ends in: m:ss" while it's on.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Sign = require(ReplicatedStorage.Shared.LuckEventSign)

local title = Config.LuckEvent.Title
local lastTimer

RunService.Heartbeat:Connect(function()
	local model = workspace:FindFirstChild("LuckEventSign")
	local board = model and model:FindFirstChild("Board")
	if not board then
		return
	end
	local now = workspace:GetServerTimeNow()
	local phase = -(now * 0.35) % 1 -- (the colours flow along the title, every frame)
	local left, nextIn = Config.luckEventLeft(now)
	local timer = if left then "Ends in: " .. Sign.clock(left) else "Starts in: " .. Sign.clock(nextIn)
	local fresh = board:GetAttribute("Drawn") == nil -- (a rebuilt sign: draw it all again)
	board:SetAttribute("Drawn", true)
	for _, gui in board:GetChildren() do
		if gui:IsA("SurfaceGui") then
			gui.Title.Text = Sign.rainbow(title, phase)
			if timer ~= lastTimer or fresh then
				gui.Timer.Text = timer
			end
		end
	end
	lastTimer = timer
end)
