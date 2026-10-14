-- The new animal cutscene (QM, Oct 13): when an animal comes home with you (a ride home, the
-- finish line), every bit of UI goes, the world behind goes hazy like frosted glass (the
-- Worlds menu's), QM's sunburst swells in turning behind, and the animal (PetFaces) pops in
-- as a black silhouette: overshoot and settle, a second in black, a squash (anticipation),
-- then it bursts into its colours with a stretch and a flash, settles, holds, rises a touch
-- and snaps away (QM, Oct 13: bigger, snappier, the sunburst clearly turning).
-- NewAnimal.show(kind) starts it and returns how long it takes (0 if there's no picture).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PetFaces = require(script.Parent.PetFaces)
local Sounds = require(script.Parent.Sounds)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Seconds: popping in (overshoot, then settle), black, the squash before the reveal, the
-- reveal's stretch, settling into its colours, holding, the rise before it goes, going.
local POP, BLACK, SQUASH, REVEAL, SETTLE, HOLD, RISE, OUT = 0.16, 0.85, 0.12, 0.12, 0.2, 1, 0.08, 0.2
local SUNBURST = "rbxassetid://85834206672187" -- assets/ui/Sunburst.png (QM's)
local BURST_SIZE, BURST_SPIN = 2.3, 80 -- x the animal's size; degrees a second (it turns a good way round)
local SIZE = 0.6 -- x the screen's height
local HAZE = { blur = 14, brightness = 0.06, contrast = -0.15, saturation = -0.35 } -- (WorldsMenu's)

local NewAnimal = {}
local busy = false

function NewAnimal.show(kind)
	local image = PetFaces.HEADSHOTS[kind]
	if busy or not image or image == "" then
		return 0
	end
	busy = true
	local total = POP * 2 + BLACK + SQUASH + REVEAL + SETTLE + HOLD + RISE + OUT
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
		local burstScale = Instance.new("UIScale")
		burstScale.Scale = 0.5
		burstScale.Parent = burst
		local spin = RunService.RenderStepped:Connect(function(dt)
			burst.Rotation = (burst.Rotation + BURST_SPIN * dt) % 360
		end)
		local flash = Instance.new("Frame") -- (the reveal's white flash)
		flash.BackgroundColor3 = Color3.new(1, 1, 1)
		flash.BackgroundTransparency = 1
		flash.Size = UDim2.fromScale(1, 1)
		flash.ZIndex = 3
		flash.Parent = gui
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

		local function tween(object, time, style, direction, goal)
			TweenService:Create(object, TweenInfo.new(time, style, direction), goal):Play()
		end
		local Quad, Back, Sine = Enum.EasingStyle.Quad, Enum.EasingStyle.Back, Enum.EasingStyle.Sine
		local In, Out = Enum.EasingDirection.In, Enum.EasingDirection.Out
		-- The sunburst swells in behind; the silhouette pops past full size and settles back,
		-- with a little twist.
		tween(burst, 0.3, Quad, Out, { ImageTransparency = 0.25 })
		tween(burstScale, 0.4, Back, Out, { Scale = 0.85 })
		face.Rotation = -10
		tween(scale, POP, Quad, Out, { Scale = 1.15 })
		tween(face, POP * 2, Back, Out, { Rotation = 0 })
		task.wait(POP)
		tween(scale, POP, Quad, Out, { Scale = 1 })
		task.wait(POP)
		-- In black, breathing a little.
		tween(scale, BLACK, Sine, Out, { Scale = 1.04 })
		task.wait(BLACK)
		-- Anticipation: it squashes down...
		tween(scale, SQUASH, Quad, In, { Scale = 0.86 })
		task.wait(SQUASH)
		-- ...and bursts into its colours, stretched past full size, with a flash and the
		-- sunburst kicking out.
		tween(scale, REVEAL, Quad, Out, { Scale = 1.2 })
		tween(face, REVEAL, Quad, Out, { ImageColor3 = Color3.new(1, 1, 1) })
		Sounds.play("reveal_pop") -- (the egg reveal's pop and its shake: QM, Oct 13)
		task.spawn(function()
			local t = 0
			while t < 0.35 do
				local k = (1 - t / 0.35) * 10
				face.Position = UDim2.new(0.5, math.random(-1, 1) * k, 0.5, math.random(-1, 1) * k)
				t += RunService.Heartbeat:Wait()
			end
			face.Position = UDim2.fromScale(0.5, 0.5)
		end)
		flash.BackgroundTransparency = 0.35
		tween(flash, 0.35, Quad, Out, { BackgroundTransparency = 1 })
		burstScale.Scale = 1.15
		burst.ImageTransparency = 0
		tween(burstScale, 0.4, Back, Out, { Scale = 1 })
		tween(burst, 0.4, Quad, Out, { ImageTransparency = 0.12 })
		task.wait(REVEAL)
		tween(scale, SETTLE, Back, Out, { Scale = 1 })
		task.wait(SETTLE + HOLD)
		-- A rise before it goes (anticipation again), then it snaps small and away.
		tween(scale, RISE, Quad, Out, { Scale = 1.08 })
		task.wait(RISE)
		tween(scale, OUT, Back, In, { Scale = 0 })
		tween(face, OUT, Quad, In, { ImageTransparency = 1 })
		tween(burstScale, OUT, Quad, In, { Scale = 0.3 })
		tween(burst, OUT, Quad, In, { ImageTransparency = 1 })
		tween(blur, OUT, Quad, In, { Size = 0 })
		tween(tint, OUT, Quad, In, { Brightness = 0, Contrast = 0, Saturation = 0 })
		task.wait(OUT)

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
