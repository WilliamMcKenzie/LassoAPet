-- The Robo Shark's hunt (QM, Oct 15): the run home's red vignette (ReturnVignette's: QM's
-- picture, the same pulse, Config.ReturnVignette) for as long as the hunt runs (QM: "just the
-- same as the ride back one").
--
--   HuntVignette.update(dt, on)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local IMAGE = "rbxassetid://124966752636756" -- assets/ui/Vignette.png (QM's, 512 px)

local HuntVignette = {}

local gui, image
local strength, t = 0, 0

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "HuntVignette"
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
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function HuntVignette.update(dt, on)
	local cfg = Config.ReturnVignette
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
	-- One pulse: in over InTime (eased), then out over OutTime, as the ride back's.
	local period = cfg.InTime + cfg.OutTime
	t = (t + dt) % period
	local k = if t < cfg.InTime then t / cfg.InTime else 1 - (t - cfg.InTime) / cfg.OutTime
	k = 0.5 - math.cos(k * math.pi) / 2
	image.ImageTransparency = cfg.MaxTransparency + (cfg.MinTransparency - cfg.MaxTransparency) * k * strength
end

return HuntVignette
