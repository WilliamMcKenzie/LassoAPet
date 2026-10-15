-- The Robo Shark's hunt (QM, Oct 15: "a red vignette when in hunting mode, VERY INTENSE"): QM's
-- vignette picture (ReturnVignette's) three deep in hard red over the whole screen, a red wash
-- across the middle, all throbbing fast, for as long as the hunt runs.
--
--   HuntVignette.update(dt, on)

local Players = game:GetService("Players")

local IMAGE = "rbxassetid://124966752636756" -- assets/ui/Vignette.png (QM's, 512 px)
local RED = Color3.fromRGB(255, 0, 0)
local IN, OUT = 0.12, 0.35 -- seconds to come up and go
local THROB = 5 -- throbs a second

local HuntVignette = {}

local gui, layers, wash
local strength, t = 0, 0

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "HuntVignette"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = -1 -- (under the rest of the UI)
	wash = Instance.new("Frame")
	wash.BorderSizePixel = 0
	wash.BackgroundColor3 = RED
	wash.BackgroundTransparency = 1
	wash.Size = UDim2.fromScale(1, 1)
	wash.Parent = gui
	layers = {}
	for i = 1, 3 do
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = IMAGE
		image.ImageColor3 = RED
		image.ScaleType = Enum.ScaleType.Stretch
		image.ImageTransparency = 1
		-- (each a touch further in, so the red reaches well into the screen)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.Size = UDim2.fromScale(1 - (i - 1) * 0.12, 1 - (i - 1) * 0.12)
		image.Parent = gui
		layers[i] = image
	end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function HuntVignette.update(dt, on)
	if not gui then
		if not on then
			return
		end
		build()
	end
	strength = math.clamp(strength + (if on then dt / IN else -dt / OUT), 0, 1)
	gui.Enabled = strength > 0
	if strength <= 0 then
		t = 0
		return
	end
	t += dt
	local throb = 0.75 + 0.25 * math.abs(math.sin(t * math.pi * THROB))
	for _, image in layers do
		image.ImageTransparency = 1 - strength * throb
	end
	wash.BackgroundTransparency = 1 - strength * throb * 0.22
end

return HuntVignette
