-- Speed lines (QM, Oct 9; drawn on the screen, Oct 11): thin white streaks shooting out
-- toward the screen's edges while you sprint, none otherwise. They used to be the
-- Creator Store's "Speedlines" particles a few studs in front of the camera, but the
-- sprint's wide, fisheye view (SprintCam) flung those off the screen just when they
-- were wanted; drawn as UI they don't care what the camera does. Config.SpeedLines.
--
--   SpeedLines.update(speed, dt) -- every frame: studs/s to show lines for (0: none; the
--                                -- ones out finish their run and fade)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SpeedLines = {}

local cfg = Config.SpeedLines
local rng = Random.new()
local gui
local lines = {} -- { frame, angle, r, speed, length, t, life }
local spare = {} -- frames done with, for the next lines
local owed = 0 -- lines due but not yet drawn (a fraction a frame at low rates)

local function screen()
	if gui and gui.Parent then
		return gui
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "SpeedLines"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -10 -- (under the HUD)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

local function newFrame()
	local f = table.remove(spare)
	if f then
		f.Visible = true
		return f
	end
	f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	-- (a streak: clear at its ends, most solid a little out from its middle)
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = f
	f.Parent = screen()
	return f
end

function SpeedLines.update(speed, dt)
	dt = dt or 1 / 60
	local view = workspace.CurrentCamera.ViewportSize
	local middle = view / 2
	local reach = middle.Magnitude -- from the middle to a corner
	-- New lines: Rate a second at Speed studs/s, more or fewer with the speed.
	if cfg.On and speed > 0 then
		owed += cfg.Rate * math.clamp(speed / cfg.Speed, 0, cfg.MaxScale) * dt
	else
		owed = 0
	end
	while owed >= 1 do
		owed -= 1
		local life = cfg.Life * rng:NextNumber(0.8, 1.2)
		table.insert(lines, {
			frame = newFrame(),
			angle = rng:NextNumber(0, 2 * math.pi),
			r = rng:NextNumber(cfg.From, cfg.From + 0.15), -- (of the way out to a corner)
			speed = rng:NextNumber(0.8, 1.2) * cfg.Travel / life,
			length = rng:NextNumber(cfg.Length * 0.6, cfg.Length * 1.4),
			thick = rng:NextNumber(cfg.Thickness * 0.6, cfg.Thickness * 1.3),
			t = 0,
			life = life,
		})
	end
	-- Each one shoots out from round the middle toward the edge, fading in and out.
	local scale = view.Y / 1000 -- (Length and Thickness are for a 1000 px tall screen)
	for i = #lines, 1, -1 do
		local l = lines[i]
		l.t += dt
		if l.t >= l.life then
			l.frame.Visible = false
			table.insert(spare, l.frame)
			table.remove(lines, i)
		else
			local f = l.t / l.life
			local r = (l.r + l.speed * l.t) * reach
			local dir = Vector2.new(math.cos(l.angle), math.sin(l.angle))
			local at = middle + dir * r
			l.frame.Position = UDim2.fromOffset(at.X, at.Y)
			l.frame.Size = UDim2.fromOffset(l.length * scale, math.max(l.thick * scale, 1))
			l.frame.Rotation = math.deg(l.angle)
			l.frame.BackgroundTransparency = 1 - cfg.Opacity * math.min(f / 0.2, 1, (1 - f) / 0.35)
		end
	end
end

return SpeedLines
