-- The run home's red vignette (QM, Oct 9): QM's picture (red at the edges, clear in the
-- middle) over the whole screen, under the rest of the UI, pulsing in over InTime
-- seconds and out over OutTime, over and over, from turning round till the leap over
-- the home line. Config.ReturnVignette.
--
--   ReturnVignette.update(dt, on)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BossChase = require(script.Parent.BossChase)

local IMAGE = "rbxassetid://124966752636756" -- assets/ui/Vignette.png (QM's, 512 px)

local ReturnVignette = {}

local gui, image, surge -- (surge: a second copy over it, as the boss cries: QM, Oct 11)
local t = 0 -- seconds into this pulse
local strength = 0 -- 0..1: eases in and out with the run home as a whole

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "ReturnVignette"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = -1 -- (under the rest of the UI)
	image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = IMAGE
	image.Size = UDim2.fromScale(1, 1)
	image.ScaleType = Enum.ScaleType.Stretch
	image.ImageTransparency = 1
	image.Parent = gui
	surge = image:Clone()
	surge.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function ReturnVignette.update(dt, on)
	local cfg = Config.ReturnVignette
	on = on and cfg.On
	if not gui then
		if not on then
			return
		end
		build()
	end
	strength = math.clamp(strength + (if on then dt else -dt) / cfg.OutTime, 0, 1)
	gui.Enabled = strength > 0
	if strength <= 0 then
		t = 0
		return
	end
	-- One pulse: in over InTime (eased), then out over OutTime.
	local period = cfg.InTime + cfg.OutTime
	t = (t + dt) % period
	local k = if t < cfg.InTime then t / cfg.InTime else 1 - (t - cfg.InTime) / cfg.OutTime
	k = 0.5 - math.cos(k * math.pi) / 2
	-- The boss's cry on the run home (BossChase.roar): the pulse held up and a second copy
	-- over it, deeper red, as loud as the cry is.
	local roar = BossChase.roar()
	local seen = math.max(k, roar) * strength
	image.ImageTransparency = cfg.MaxTransparency + (cfg.MinTransparency - cfg.MaxTransparency) * seen
	surge.ImageTransparency = 1 - roar * strength
end

return ReturnVignette
