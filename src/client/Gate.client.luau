-- The gates at the biome lines you haven't unlocked: a sheet across the
-- corridor, yellow at the floor fading to clear GateHeight studs up, with QM's
-- "Zone Locked" card on it (each biome's GateImage). Only you see your gates; each one fades away
-- when your pen reaches its level (PenLevel). The ride stops you at them.
-- Buying the level (ZoneUnlocked, from PenLevel.server) plays it on camera
-- instead: the camera flies over to the gate, it shatters, and flies back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local SHARDS_X, SHARDS_Y = 14, 7 -- the gate breaks into this many pieces
local SHARD_TIME = 1.6 -- seconds the pieces fly before they're gone
local FLY_TIME = 1.6 -- seconds for the camera to get to the gate (and 1.2 back)
local PIXELS_PER_STUD = 20
local CARD_HEIGHT = 0.55 -- of the gate's height
local CARD_ASPECT = 1068 / 662 -- GateDesert.png etc.

local gates = {} -- [biome index] = { part, fades }

local function build(i)
	local width, height = Config.CourseHalfWidth * 2, Config.GateHeight
	local part = Instance.new("Part")
	part.Name = "Gate" .. i
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(width, height, 0.2)
	part.CFrame = CFrame.new(0, height / 2, WorldColors.biomeStart(i))

	local fades = {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- faces home (+z), the way you ride up to it
	gui.CanvasSize = Vector2.new(width, height) * PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Adornee = part

	local sheet = Instance.new("Frame")
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BorderSizePixel = 0
	local color = Config.Biomes[i].GateColor or Config.GateColor -- each biome's own (QM)
	sheet.BackgroundColor3 = color
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90 -- top (0) to bottom (1)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0.75),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	gradient.Parent = sheet
	sheet.Parent = gui
	table.insert(fades, { sheet, "BackgroundTransparency" })

	local image = Config.Biomes[i].GateImage
	local card
	if image and image ~= "" then
		card = Instance.new("ImageLabel")
		card.Image = image
		card.BackgroundTransparency = 1
		table.insert(fades, { card, "ImageTransparency" })
	else
		card = Instance.new("TextLabel") -- until the card image is uploaded
		card.Text = "LV. " .. i .. " REQUIRED"
		card.Font = Enum.Font.FredokaOne
		card.TextScaled = true
		card.TextColor3 = Color3.new(1, 1, 1)
		card.BackgroundColor3 = color
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 6
		stroke.Parent = card
		Instance.new("UICorner", card).CornerRadius = UDim.new(0.15, 0)
		table.insert(fades, { card, "TextTransparency" })
		table.insert(fades, { card, "BackgroundTransparency" })
		table.insert(fades, { stroke, "Transparency" })
	end
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromScale(CARD_HEIGHT * height * CARD_ASPECT / width, CARD_HEIGHT)
	card.Parent = sheet

	gui.Parent = player:WaitForChild("PlayerGui")
	part.Parent = workspace
	gates[i] = { part = part, gui = gui, fades = fades }
end

local function unlock(i)
	local gate = gates[i]
	gates[i] = nil
	local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, fade in gate.fades do
		TweenService:Create(fade[1], info, { [fade[2]] = 1 }):Play()
	end
	task.delay(0.7, function()
		gate.gui:Destroy()
		gate.part:Destroy()
	end)
end

-- The gate bursts into pieces flung on into the biome, tumbling and fading.
local function shatter(i)
	local width, height = Config.CourseHalfWidth * 2, Config.GateHeight
	local z = WorldColors.biomeStart(i)
	local w, h = width / SHARDS_X, height / SHARDS_Y
	local rng = Random.new()
	local shards = {}
	for gx = 1, SHARDS_X do
		for gy = 1, SHARDS_Y do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Material = Enum.Material.Neon
			part.Color = if rng:NextNumber() < 0.3 then Color3.new(1, 1, 1) else Config.Biomes[i].GateColor or Config.GateColor
			part.Transparency = 0.15 + 0.5 * (gy - 1) / SHARDS_Y -- clearer higher up, like the sheet
			part.Size = Vector3.new(w * rng:NextNumber(0.6, 1), h * rng:NextNumber(0.6, 1), 0.3)
			local at = Vector3.new(-width / 2 + (gx - 0.5) * w, (gy - 0.5) * h, z)
			part.CFrame = CFrame.new(at)
			part.Parent = workspace
			table.insert(shards, {
				part = part,
				start = part.Transparency,
				velocity = Vector3.new((at.X / width) * rng:NextNumber(20, 40), rng:NextNumber(8, 30), -rng:NextNumber(25, 60)),
				spin = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8)),
			})
		end
	end
	local t = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		t += dt
		for _, s in shards do
			s.velocity -= Vector3.new(0, 60 * dt, 0)
			s.part.CFrame = (s.part.CFrame + s.velocity * dt) * CFrame.Angles(s.spin.X * dt, s.spin.Y * dt, s.spin.Z * dt)
			s.part.Transparency = s.start + (1 - s.start) * math.clamp(t / SHARD_TIME, 0, 1) ^ 2
		end
		if t >= SHARD_TIME then
			connection:Disconnect()
			for _, s in shards do
				s.part:Destroy()
			end
		end
	end)
end

-- Just bought biome i: fly over to its gate, break it, fly back.
local function breakOpen(i)
	local gate = gates[i]
	gates[i] = nil
	local z = WorldColors.biomeStart(i)
	controls:Disable()
	local start = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	local view = CFrame.lookAt(Vector3.new(0, 30, z + 70), Vector3.new(0, 9, z))
	local out = TweenService:Create(camera, TweenInfo.new(FLY_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = view })
	out:Play()
	out.Completed:Wait()
	task.wait(0.5)
	gate.gui:Destroy()
	gate.part:Destroy()
	shatter(i)
	-- a jolt as it goes
	local shake = TweenService:Create(camera, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 3, true), { CFrame = view * CFrame.new(0, 0.6, 0) })
	shake:Play()
	task.wait(SHARD_TIME + 0.3)
	local back = TweenService:Create(camera, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = start })
	back:Play()
	back.Completed:Wait()
	camera.CameraType = Enum.CameraType.Custom
	controls:Enable()
end

-- [biome index] = true: break it on camera when PenLevel gets there. The event
-- is sent first, but in case PenLevel arrives first, refresh waits a moment
-- before quietly fading a gate.
local bought = {}
ReplicatedStorage:WaitForChild("ZoneUnlocked").OnClientEvent:Connect(function(i)
	if gates[i] and i <= (player:GetAttribute("PenLevel") or 1) then
		task.spawn(breakOpen, i)
	else
		bought[i] = true
	end
end)

local function refresh()
	local level = player:GetAttribute("PenLevel") or 1
	for i = 2, #Config.Biomes do
		if i > level and not gates[i] then
			build(i)
		elseif i <= level and gates[i] then
			if bought[i] then
				bought[i] = nil
				task.spawn(breakOpen, i)
			else
				task.delay(0.5, function()
					if gates[i] then
						unlock(i)
					end
				end)
			end
		end
	end
end

player:GetAttributeChangedSignal("PenLevel"):Connect(refresh)
refresh()
