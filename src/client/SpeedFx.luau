-- The feel of speed (QM, Oct 7): the Speed stat (and the m/s it shows) is uncapped,
-- but how fast a ride really travels is curved off past Config.SpeedCurve.Knee
-- towards Max, and speed lines plus a wider field of view sell the rest.
--
--   SpeedFx.curve(speed)      -- studs/s asked for -> studs/s actually travelled
--   SpeedFx.update(dt, feel)  -- every frame: feel = the uncurved speed (0 off the ride)
--   SpeedFx.fovKick()         -- degrees to add to the ride camera's field of view

local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local CURVE = Config.SpeedCurve
local FEEL = Config.SpeedFeel

local SpeedFx = {}

function SpeedFx.curve(speed)
	if not CURVE.On or speed <= CURVE.Knee then
		return speed
	end
	-- Straight up to the knee, then a tanh bend that never quite reaches Max.
	local room = CURVE.Max - CURVE.Knee
	return CURVE.Knee + room * math.tanh((speed - CURVE.Knee) / room)
end

local rng = Random.new()
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedLines"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = -10 -- under the HUD
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.4),
	NumberSequenceKeypoint.new(1, 0),
})

local lines = {}
for i = 1, (FEEL.Lines or 0) do
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.Visible = false
	local fade = Instance.new("UIGradient")
	fade.Transparency = FADE -- clear at the inner end, solid at the outer
	fade.Parent = frame
	frame.Parent = gui
	lines[i] = { frame = frame, r = 2 }
end

local function respawn(line, anywhere)
	line.angle = rng:NextNumber(0, 2 * math.pi)
	-- (radius and length as shares of half the screen's diagonal; the centre stays clear)
	line.r = if anywhere then rng:NextNumber(0.5, 1.1) else rng:NextNumber(0.5, 0.7)
	line.len = rng:NextNumber(0.12, 0.3)
	line.width = rng:NextNumber(1.5, 3.5)
	line.pace = rng:NextNumber(0.8, 1.2)
end

local intensity = 0

function SpeedFx.update(dt, feel)
	local target = if FEEL.On and feel > FEEL.Start then 1 - math.exp(-(feel - FEEL.Start) / FEEL.Scale) else 0
	intensity += (target - intensity) * (1 - math.exp(-4 * dt))
	local count = math.floor(#lines * intensity + 0.5)
	local view = workspace.CurrentCamera.ViewportSize
	local half = view.Magnitude / 2
	for i, line in lines do
		local frame = line.frame
		if i > count then
			if frame.Visible then
				frame.Visible = false
				line.r = 2 -- (respawns when it shows again)
			end
			continue
		end
		if line.r > 1.15 then
			respawn(line, not frame.Visible)
		end
		-- Faster the faster you go.
		line.r += dt * FEEL.LineSpeed * line.pace * (0.5 + intensity)
		local dir = Vector2.new(math.cos(line.angle), math.sin(line.angle))
		local mid = view / 2 + dir * (line.r + line.len / 2) * half
		frame.Position = UDim2.fromOffset(mid.X, mid.Y)
		frame.Size = UDim2.fromOffset(line.len * half, line.width)
		frame.Rotation = math.deg(line.angle)
		frame.BackgroundTransparency = 1 - FEEL.Opacity * intensity
		frame.Visible = true
	end
end

function SpeedFx.fovKick()
	return FEEL.On and FEEL.FovKick * intensity or 0
end

return SpeedFx
