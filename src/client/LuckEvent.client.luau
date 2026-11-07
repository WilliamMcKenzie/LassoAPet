-- The 100x Luck Event's sign (Config.LuckEvent, QM Nov 7): rolls the rainbow along the title on
-- workspace.LuckEventSign's Board (Shared/LuckEventSign) and counts down under it: "Starts in:
-- m:ss", or "Ends in: m:ss" while it's on.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Sign = require(ReplicatedStorage.Shared.LuckEventSign)

local title = Config.LuckEvent.Title
local lastShift, lastTimer

RunService.Heartbeat:Connect(function()
	local model = workspace:FindFirstChild("LuckEventSign")
	local board = model and model:FindFirstChild("Board")
	if not board then
		return
	end
	local now = workspace:GetServerTimeNow()
	local shift = math.floor(now * 4) -- (the colours roll along four letters a second)
	local left, nextIn = Config.luckEventLeft(now)
	local timer = if left then "Ends in: " .. Sign.clock(left) else "Starts in: " .. Sign.clock(nextIn)
	local fresh = board:GetAttribute("Drawn") == nil -- (a rebuilt sign: draw it all again)
	board:SetAttribute("Drawn", true)
	for _, gui in board:GetChildren() do
		if gui:IsA("SurfaceGui") then
			if shift ~= lastShift or fresh then
				gui.Title.Text = Sign.rainbow(title, -shift)
			end
			if timer ~= lastTimer or fresh then
				gui.Timer.Text = timer
			end
		end
	end
	lastShift, lastTimer = shift, timer
end)
