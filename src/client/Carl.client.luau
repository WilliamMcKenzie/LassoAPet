-- Carl's stall (Config.Carl, QM Oct 4): QM's market stall (CarlStallModel) in the gap between
-- the left corner pen and the start line, with a cactus growing out of it and
-- Carl (a cactus guy) behind the counter. Walk up and Talk: he asks if you want
-- to spin for a pet, and Yes opens the egg roll menu (RollMenu; the roll is Hud's).
--
-- Built here on each client rather than in the map, so Carl can play his idle
-- animation and tuning the stall needs no map reload. Everyone sees the same stall.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Cactus = require(ReplicatedStorage.Shared.Animals.Cactus)
local StallModel = require(ReplicatedStorage.Shared.CarlStallModel)
local RollMenu = require(script.Parent.RollMenu)

if not Config.Gacha.Enabled then
	return
end

local STUDS = "rbxassetid://7447638591" -- the classic stud decal the animals use
local STUD_TILE = 0.5
local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide

local SAND = Color3.fromRGB(236, 200, 130)

local player = Players.LocalPlayer
local carlConfig = Config.Carl
-- The stall's frame: front (the counter) toward the base (+z), back to the start line.
local origin = CFrame.new(carlConfig.Position) * CFrame.Angles(0, math.pi, 0)

local stall = Instance.new("Model")
stall.Name = "CarlStall"

-- A studded block, `size` big, at `at` in the stall's frame.
local function block(name, size, at, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = origin * at
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for _, face in Enum.NormalId:GetEnumItems() do
		local texture = Instance.new("Texture")
		texture.Texture = STUDS
		texture.StudsPerTileU = STUD_TILE
		texture.StudsPerTileV = STUD_TILE
		texture.Face = face
		texture.Parent = part
	end
	part.Parent = stall
	return part
end

local function text(parent, size, value, thickness)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = value
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 3
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function money(amount)
	if amount >= 1e6 then
		return "$" .. string.format("%g", amount / 1e6) .. "M"
	elseif amount >= 1e3 then
		return "$" .. string.format("%g", amount / 1e3) .. "k"
	end
	return "$" .. amount
end

-- Carl first: the stall is sized around him.
local carl = Cactus.new()
carl:setSaddled(false)
for _, part in carl.model:GetDescendants() do
	if part:IsA("BasePart") then
		part.CanCollide = false
		part.CanQuery = false
	end
end
local carlRootY = carl.model.PrimaryPart.Position.Y
local _, carlSize = carl.model:GetBoundingBox()
local h = carlSize.Y

-- QM's stall (designs/stall/CarlStall.bbmodel -> tools/carl_stall.py -> CarlStallModel): posts,
-- beams, a counter and a striped cloth roof, with a cactus growing up through it.
local counter
for _, spec in StallModel.parts do
	local part = block(spec.name, spec.size, spec.cframe, spec.color)
	if spec.name == "Counter" then
		counter = part
	end
end
local roofTop = 0
for _, spec in StallModel.parts do
	roofTop = math.max(roofTop, spec.cframe.Position.Y + spec.size.Y / 2)
end
-- The sign on the counter's front, toward the base.
local boardGui = Instance.new("SurfaceGui")
boardGui.Face = Enum.NormalId.Front
boardGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
boardGui.PixelsPerStud = 40
boardGui.LightInfluence = 0
text(boardGui, UDim2.fromScale(0.9, 0.6), "CARL'S PET SPIN").Position = UDim2.fromScale(0.05, 0.2)
boardGui.Parent = counter

-- The heap of eggs behind him (QM, Oct 4): every egg the roll gives, at its real size.
for _, spec in StallModel.pile do
	local egg = Egg.new(spec.kind).model
	for _, part in egg:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
		end
	end
	egg:PivotTo(origin * spec.cframe)
	egg.Parent = stall
end

-- Carl behind the counter, facing the base, his name over his head.
local CARL_AT = CFrame.new(StallModel.carl)
local tag = Instance.new("BillboardGui")
tag.Name = "Name"
tag.Size = UDim2.fromOffset(120, 40)
tag.StudsOffsetWorldSpace = Vector3.new(0, math.max(h, roofTop) - carlRootY + 1.5, 0) -- over the roof
tag.MaxDistance = 150
tag.Adornee = carl.model.PrimaryPart
text(tag, UDim2.fromScale(1, 1), "Carl").TextColor3 = Color3.fromRGB(150, 255, 140)
tag.Parent = stall

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "TalkPrompt"
prompt.ActionText = "Talk"
prompt.ObjectText = "Carl"
prompt.RequiresLineOfSight = false
prompt.MaxActivationDistance = carlConfig.Reach
prompt.Parent = counter

carl.model.Parent = stall
stall.Parent = workspace

-- The chat: Carl's line at the bottom of the screen, with Yes and No.
local gui = Instance.new("ScreenGui")
gui.Name = "CarlChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 3
gui.Enabled = false

local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
local rootScale = Instance.new("UIScale")
rootScale.Parent = root
local camera = workspace.CurrentCamera
local function resize()
	local screen = camera.ViewportSize
	rootScale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
	root.Size = UDim2.fromOffset(screen.X / rootScale.Scale, screen.Y / rootScale.Scale)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -40)
panel.Size = UDim2.fromOffset(620, 200)
panel.BackgroundColor3 = SAND
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = panel
local edge = Instance.new("UIStroke")
edge.Thickness = 5
edge.Color = Color3.fromRGB(110, 70, 36)
edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
edge.Parent = panel
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root

local name = text(panel, UDim2.fromOffset(140, 44), "CARL", 4)
name.TextColor3 = Color3.fromRGB(150, 255, 140)
name.Position = UDim2.fromOffset(24, -26)

local line = text(panel, UDim2.new(1, -48, 0, 70), "")
line.Position = UDim2.fromOffset(24, 26)
line.TextWrapped = true

local function choice(label, color, x)
	local button = Instance.new("TextButton")
	button.Name = label
	button.AutoButtonColor = false
	button.Text = ""
	button.BackgroundColor3 = color
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, x, 1, -20)
	button.Size = UDim2.fromOffset(190, 64)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 16)
	round.Parent = button
	local outline = Instance.new("UIStroke")
	outline.Thickness = 5
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Parent = button
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local caption = text(button, UDim2.fromScale(1, 0.8), label, 4)
	caption.Position = UDim2.fromScale(0, 0.1)
	local press = TweenInfo.new(0.08)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, press, { Scale = 0.93 }):Play()
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, press, { Scale = 1 }):Play()
		end)
	end
	button.Parent = panel
	return button
end
local yes = choice("YES", Color3.fromRGB(92, 214, 72), -110)
local no = choice("NO", Color3.fromRGB(235, 72, 72), 110)

root.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local talking = false
local hop = 0 -- seconds left of Carl's hop

local function close()
	talking = false
	gui.Enabled = false
	prompt.Enabled = true
end

prompt.Triggered:Connect(function()
	if talking then
		return
	end
	talking = true
	prompt.Enabled = false
	hop = 0.45
	line.Text = "Howdy partner! Wanna spin for a pet? Just " .. money(Config.Gacha.Price) .. " a spin!"
	line.MaxVisibleGraphemes = 0
	gui.Enabled = true
	panelScale.Scale = 0.85
	TweenService:Create(panelScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.spawn(function()
		local length = utf8.len(line.Text) or #line.Text
		for i = 1, length do
			if not talking then
				break
			end
			line.MaxVisibleGraphemes = i
			task.wait(0.02)
		end
		line.MaxVisibleGraphemes = -1
	end)
end)

yes.Activated:Connect(function()
	close()
	if not RollMenu.isOpen() then
		RollMenu.toggle()
	end
end)
no.Activated:Connect(close)

-- Carl idles, turns to whoever's talking to him and hops when you say hi. The
-- chat closes once you walk off.
local yaw = 0
RunService.Heartbeat:Connect(function(dt)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local here = (origin * CARL_AT).Position
	local away = if hrp then (hrp.Position - here) * Vector3.new(1, 0, 1) else nil
	if talking and (not away or away.Magnitude > carlConfig.Reach + 8) then
		close()
	end
	if away and away.Magnitude > 200 then
		return -- too far to see him move
	end
	local target = 0
	if talking and away and away.Magnitude > 0.1 then
		local inFrame = origin:VectorToObjectSpace(away)
		target = math.clamp(math.atan2(-inFrame.X, -inFrame.Z), -1, 1)
	end
	yaw += (target - yaw) * math.min(1, dt * 8)
	hop = math.max(0, hop - dt)
	local lift = math.sin(hop / 0.45 * math.pi) * 0.6 -- (low: the roof is just over his head)
	carl:update(dt, 0, 0)
	-- (a model faces its -z, as the stall's frame does: so no extra turn)
	carl.model.PrimaryPart.CFrame = origin * CARL_AT * CFrame.new(0, carlRootY + lift, 0) * CFrame.Angles(0, yaw, 0)
end)
