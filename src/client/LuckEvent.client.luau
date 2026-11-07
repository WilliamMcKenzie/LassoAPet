-- The 100x Luck Event's sign (Config.LuckEvent, QM Nov 7): on workspace.LuckEventSign's Board
-- (Server/LuckEvent), both faces, the title in rainbow letters that roll along, and under it
-- "Starts in: m:ss" (or "Ends in: m:ss" while it's on).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local sign = workspace:WaitForChild("LuckEventSign")
local board = sign:WaitForChild("Board")

local CFG = Config.LuckEvent
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local W, H = 1040, 300 -- the canvas (20 pixels a stud: Config.LuckEvent.Sign 52 x 15)
local RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(170, 90, 240),
}

local function clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- the title in rich text, letter k coloured RAINBOW[(k + shift)], spaces skipped
local function rainbow(text, shift)
	local out, k = {}, 0
	for _, code in utf8.codes(text) do
		local ch = utf8.char(code)
		if ch == " " then
			table.insert(out, ch)
		else
			local c = RAINBOW[(k + shift) % #RAINBOW + 1]
			table.insert(out, string.format('<font color="rgb(%d,%d,%d)">%s</font>', math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255), ch))
			k += 1
		end
	end
	return table.concat(out)
end

local titles, timers = {}, {}
for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do -- (Back faces the base, +z)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "LuckEvent" .. face.Name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(W, H)
	gui.LightInfluence = 0
	gui.MaxDistance = 600
	gui.ResetOnSpawn = false
	gui.Adornee = board
	local function label(y, h)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(20, y)
		l.Size = UDim2.fromOffset(W - 40, h)
		l.FontFace = FONT
		l.TextScaled = true
		l.RichText = true
		l.TextColor3 = Color3.new(1, 1, 1)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(30, 22, 40)
		stroke.Thickness = 5
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = l
		l.Parent = gui
		return l
	end
	table.insert(titles, label(34, 140))
	table.insert(timers, label(190, 76))
	gui.Parent = player:WaitForChild("PlayerGui")
end

local lastShift, lastTimer
RunService.Heartbeat:Connect(function()
	local now = workspace:GetServerTimeNow()
	local shift = math.floor(now * 4) -- (the colours roll along four letters a second)
	local left, nextIn = Config.luckEventLeft(now)
	local timer = if left then "Ends in: " .. clock(left) else "Starts in: " .. clock(nextIn)
	if shift ~= lastShift then
		lastShift = shift
		for _, l in titles do
			l.Text = rainbow(CFG.Title, -shift)
		end
	end
	if timer ~= lastTimer then
		lastTimer = timer
		for _, l in timers do
			l.Text = timer
		end
	end
end)
