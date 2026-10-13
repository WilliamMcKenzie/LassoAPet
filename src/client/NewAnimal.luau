-- The new animal cutscene (QM, Oct 13): when an animal comes home with you (a ride home, the
-- finish line), every bit of UI goes, the world behind goes hazy like frosted glass (the
-- Worlds menu's), and the animal's headshot (PetFaces) bounces in, fading from black to its
-- colours, with QM's sunburst turning behind it, holds a moment, then fades and shrinks
-- away (QM: snappy). NewAnimal.show(kind) starts it and returns how
-- long it takes (0 if there's no headshot for it).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PetFaces = require(script.Parent.PetFaces)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local POP_IN, HOLD, POP_OUT = 0.3, 0.6, 0.3 -- seconds (it goes from black to its colours as it pops in)
local SUNBURST = "rbxassetid://85834206672187" -- assets/ui/Sunburst.png (QM's)
local BURST_SIZE, BURST_SPIN = 2.1, 45 -- x the headshot's size; degrees a second
local SIZE = 0.42 -- x the screen's height
local HAZE = { blur = 14, brightness = 0.06, contrast = -0.15, saturation = -0.35 } -- (WorldsMenu's)

local NewAnimal = {}
local busy = false

function NewAnimal.show(kind)
	local image = PetFaces.HEADSHOTS[kind]
	if busy or not image or image == "" then
		return 0
	end
	busy = true
	local total = POP_IN + HOLD + POP_OUT
	task.spawn(function()
		player:SetAttribute("Cutscene", true)
		local hidden = {}
		local function hideAll()
			for _, g in player.PlayerGui:GetChildren() do
				if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "NewAnimal" then
					g.Enabled = false
					if not table.find(hidden, g) then
						table.insert(hidden, g)
					end
				end
			end
		end
		hideAll()
		local holdHidden = RunService.RenderStepped:Connect(hideAll) -- (some of it turns itself back on)

		local blur = Instance.new("BlurEffect")
		blur.Size = 0
		blur.Parent = camera
		local tint = Instance.new("ColorCorrectionEffect")
		tint.Parent = camera
		local haze = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(blur, haze, { Size = HAZE.blur }):Play()
		TweenService:Create(tint, haze, { Brightness = HAZE.brightness, Contrast = HAZE.contrast, Saturation = HAZE.saturation }):Play()

		local gui = Instance.new("ScreenGui")
		gui.Name = "NewAnimal"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 50
		local burst = Instance.new("ImageLabel")
		burst.BackgroundTransparency = 1
		burst.Image = SUNBURST
		burst.ImageTransparency = 1
		burst.AnchorPoint = Vector2.new(0.5, 0.5)
		burst.Position = UDim2.fromScale(0.5, 0.5)
		burst.Size = UDim2.fromScale(SIZE * BURST_SIZE, SIZE * BURST_SIZE)
		local burstAspect = Instance.new("UIAspectRatioConstraint")
		burstAspect.DominantAxis = Enum.DominantAxis.Height
		burstAspect.Parent = burst
		burst.Parent = gui
		local spin = RunService.RenderStepped:Connect(function(dt)
			burst.Rotation = (burst.Rotation + BURST_SPIN * dt) % 360
		end)
		local face = Instance.new("ImageLabel")
		face.BackgroundTransparency = 1
		face.Image = image
		face.ImageColor3 = Color3.new(0, 0, 0) -- (black first, then its colours)
		face.AnchorPoint = Vector2.new(0.5, 0.5)
		face.Position = UDim2.fromScale(0.5, 0.5)
		face.Size = UDim2.fromScale(SIZE, SIZE)
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.DominantAxis = Enum.DominantAxis.Height
		aspect.Parent = face
		local scale = Instance.new("UIScale")
		scale.Scale = 0
		scale.Parent = face
		face.ZIndex = 2
		face.Parent = gui
		gui.Parent = player.PlayerGui

		TweenService:Create(scale, TweenInfo.new(POP_IN, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		TweenService:Create(face, TweenInfo.new(POP_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageColor3 = Color3.new(1, 1, 1) }):Play()
		TweenService:Create(burst, TweenInfo.new(POP_IN), { ImageTransparency = 0.15 }):Play()
		task.wait(POP_IN + HOLD)
		local out = TweenInfo.new(POP_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(scale, out, { Scale = 0 }):Play()
		TweenService:Create(face, out, { ImageTransparency = 1 }):Play()
		TweenService:Create(burst, out, { ImageTransparency = 1, Size = UDim2.fromScale(0, 0) }):Play()
		TweenService:Create(blur, out, { Size = 0 }):Play()
		TweenService:Create(tint, out, { Brightness = 0, Contrast = 0, Saturation = 0 }):Play()
		task.wait(POP_OUT)

		spin:Disconnect()
		gui:Destroy()
		blur:Destroy()
		tint:Destroy()
		holdHidden:Disconnect()
		for _, g in hidden do
			g.Enabled = true
		end
		player:SetAttribute("Cutscene", nil)
		busy = false
	end)
	return total + 0.15 -- (the UI's back just before: the ride's own end goes after)
end

-- (the server's own: /give, Hatchery)
task.spawn(function()
	game:GetService("ReplicatedStorage"):WaitForChild("NewAnimal").OnClientEvent:Connect(NewAnimal.show)
end)

return NewAnimal
