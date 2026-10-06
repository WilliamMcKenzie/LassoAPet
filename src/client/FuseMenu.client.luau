-- FUSE (QM, Oct 6; Shared/Fusion): at home, the Fuse button (Hud's, under Pets) lets
-- you tap two of your pets (in the pen, or the one waiting on its
-- spot). A preview shows the hybrid they'd make, turning slowly in 3D, what it's
-- called and what it earns; FUSE! makes it (Hatchery.server's FusePets). The rarer
-- pet is the base; the other sets its size and paints it in its colours. Hybrids
-- don't fuse again, and two of the same kind merge instead (MERGE).
--
-- Its own script, as Ride.client is at its limits.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Hud = require(script.Parent.Hud)
local PenPets = require(script.Parent.PenPets)
local Sounds = require(script.Parent.Sounds)

local Animals = ReplicatedStorage.Shared.Animals
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FONT = Enum.Font.FredokaOne
local REFERENCE_WIDTH = 1320 -- as Hud's
local HOME_REACH = 30 -- studs outside your pen's fence the button still shows
local PINK = Color3.fromRGB(236, 72, 160)

local state = { picks = {}, marks = {} } -- picks: { { id, kind, fuse, model } }

local function stroked(object, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = if object:IsA("TextLabel") or object:IsA("TextButton") then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border
	s.Parent = object
	return s
end

local function text(parent, size, position, textSize)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = textSize
	label.Size = size
	label.Position = position
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	stroked(label, 3)
	label.Parent = parent
	return label
end

local function pill(parent, caption, color, size, position, onActivated)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = color
	b.Size = size
	b.Position = position
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Font = FONT
	b.Text = caption
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = math.floor(size.Y.Offset * 0.5)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = b
	stroked(b, 3).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = 3
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	textStroke.Parent = b
	local scale = Instance.new("UIScale")
	scale.Parent = b
	b.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.93 }):Play()
	end)
	for _, event in { b.MouseButton1Up, b.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 1 }):Play()
		end)
	end
	b.Activated:Connect(onActivated)
	b.Parent = parent
	return b
end

-- The screen: sized like Hud's, so it scales the same on every screen.
local gui = Instance.new("ScreenGui")
gui.Name = "FuseHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
local rootScale = Instance.new("UIScale")
rootScale.Parent = root
root.Parent = gui
local function resize()
	local screen = if gui.AbsoluteSize.X > 0 then gui.AbsoluteSize else camera.ViewportSize
	rootScale.Scale = screen.X / REFERENCE_WIDTH * (Config.HudScale or 1)
	root.Size = UDim2.fromOffset(screen.X / rootScale.Scale, screen.Y / rootScale.Scale)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()

local tip = text(root, UDim2.fromOffset(600, 50), UDim2.new(0.5, 0, 0, 120), 40)
tip.Visible = false
local cancelButton

-- The preview: the hybrid turning in a little 3D window.
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.48)
panel.Size = UDim2.fromOffset(440, 520)
panel.BackgroundColor3 = Color3.fromRGB(255, 214, 96)
panel.Visible = false
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 28)
panelCorner.Parent = panel
stroked(panel, 4)
panel.Parent = root
local viewport = Instance.new("ViewportFrame")
viewport.BackgroundTransparency = 1
viewport.Size = UDim2.fromOffset(400, 330)
viewport.Position = UDim2.fromOffset(20, 64)
viewport.Ambient = Color3.fromRGB(190, 190, 190)
viewport.LightColor = Color3.new(1, 1, 1)
viewport.LightDirection = Vector3.new(-1, -2, -1)
viewport.Parent = panel
local world = Instance.new("WorldModel")
world.Parent = viewport
local viewCamera = Instance.new("Camera")
viewCamera.FieldOfView = 30
viewCamera.Parent = viewport
viewport.CurrentCamera = viewCamera
local title = text(panel, UDim2.new(1, -20, 0, 50), UDim2.new(0.5, 0, 0, 38), 38)
local earns = text(panel, UDim2.new(1, -20, 0, 36), UDim2.new(0.5, 0, 0, 404), 30)

local preview -- { animal, center, radius, spin }

local function money(n)
	local s = tostring(math.floor(n))
	while true do
		local k
		s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			return "$" .. s
		end
	end
end

local function clearPreview()
	if preview then
		preview.animal.model:Destroy()
		preview = nil
	end
	panel.Visible = false
end

local function clearMarks()
	for _, mark in state.marks do
		mark:Destroy()
	end
	table.clear(state.marks)
end

local function stop()
	state.active = false
	table.clear(state.picks)
	clearMarks()
	clearPreview()
	tip.Visible = false
	cancelButton.Visible = false
end

-- What a pet earns a second: a hybrid what both its pets did; a merged one for all of them.
local function incomeOf(pick)
	return pick.income or (Config.PetIncome[pick.kind] or 0) * (pick.merged or 1)
end

local function showPreview()
	local a, b = state.picks[1], state.picks[2]
	local base, donor = Fusion.order(a.kind, b.kind)
	local ok, class = pcall(require, Animals[base])
	if not ok then
		stop()
		return
	end
	local animal = class.new()
	animal:setSaddled(false)
	Fusion.paint(animal.model, base, donor)
	animal.model:PivotTo(CFrame.new())
	animal.model.Parent = world
	local cf, size = animal.model:GetBoundingBox()
	preview = { animal = animal, center = cf.Position, radius = size.Magnitude / 2, spin = 0 }
	title.Text = Fusion.name(base, donor)
	local scale = Fusion.scale(base, donor)
	local sizeWord = if scale < 0.99 then "tiny " elseif scale > 1.01 then "giant " else ""
	earns.Text = "A " .. sizeWord .. base:gsub("(%l)(%u)", "%1 %2") .. ", earns " .. money(incomeOf(a) + incomeOf(b)) .. "/s"
	panel.Visible = true
	tip.Visible = false
end

-- Each frame the preview turns slowly, idling, seen from a little above.
RunService.RenderStepped:Connect(function(dt)
	if not preview then
		return
	end
	preview.spin += dt * 0.6
	pcall(preview.animal.update, preview.animal, dt, 0, 0)
	local dist = preview.radius / math.sin(math.rad(viewCamera.FieldOfView) / 2) * 1.05
	local dir = Vector3.new(-math.sin(preview.spin) * math.cos(0.25), math.sin(0.25), -math.cos(preview.spin) * math.cos(0.25))
	viewCamera.CFrame = CFrame.lookAt(preview.center + dir * dist, preview.center)
end)

local function mark(model, n)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(60, 60)
	bb.AlwaysOnTop = true
	bb.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y / 2 + 2, 0)
	bb.Adornee = model.PrimaryPart
	local label = text(bb, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), 48)
	label.Text = tostring(n)
	label.TextColor3 = PINK
	bb.Parent = gui
	table.insert(state.marks, bb)
end

-- Your pets you can pick: [model] = { id, kind, fuse, merged, income }
local function yours()
	local list = {}
	for model, pet in PenPets.pets do
		if model.Parent then
			list[model] = pet
		end
	end
	local starter = PenPets.starter
	if starter and starter.animal.model.Parent and starter.kind == player:GetAttribute("RidePet") then
		list[starter.animal.model] = { id = "ride", kind = starter.kind, fuse = starter.fuse, merged = starter.merged,
			income = player:GetAttribute("RideIncome") }
	end
	return list
end

local function flash(message)
	tip.Text = message
	tip.Visible = true
	task.delay(1.6, function()
		if state.active and #state.picks < 2 then
			tip.Text = if #state.picks == 0 then "Tap two pets to fuse" else "Now tap another pet"
		end
	end)
end

local function pick(model, pet)
	if pet.fuse then
		flash("Hybrids can't fuse again")
		return
	end
	for _, p in state.picks do
		if p.model == model then
			return
		end
		if p.kind == pet.kind then
			flash("Pick a different animal")
			return
		end
	end
	table.insert(state.picks, { id = pet.id, kind = pet.kind, merged = pet.merged, income = pet.income, model = model })
	mark(model, #state.picks)
	Sounds.play("merge_pop")
	if #state.picks == 2 then
		showPreview()
	else
		tip.Text = "Now tap another pet"
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not state.active or processed or panel.Visible then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local pets = yours()
	local models = {}
	for model in pets do
		table.insert(models, model)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = models
	local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	local part = hit and hit.Instance
	while part and not pets[part] do
		part = part.Parent
	end
	if part then
		pick(part, pets[part])
	end
end)

local function start()
	stop()
	state.active = true
	tip.Text = "Tap two pets to fuse"
	tip.Visible = true
	cancelButton.Visible = true
end

cancelButton = pill(root, "X", Color3.fromRGB(230, 60, 60), UDim2.fromOffset(64, 64), UDim2.new(0.5, 340, 0, 120), stop)
cancelButton.Visible = false

pill(panel, "FUSE!", PINK, UDim2.fromOffset(200, 70), UDim2.new(0.5, -105, 1, -56), function()
	local a, b = state.picks[1], state.picks[2]
	if a and b then
		ReplicatedStorage:WaitForChild("FusePets"):FireServer(a.id, b.id)
		Sounds.play("merge_poof")
	end
	stop()
end)
pill(panel, "Cancel", Color3.fromRGB(150, 160, 175), UDim2.fromOffset(170, 70), UDim2.new(0.5, 105, 1, -56), stop)

-- Whether you're at home: in or by your pen, on foot.
local function atHome()
	if player:GetAttribute("Tutorial") then
		return false
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local index = player:GetAttribute("Pen")
	local pen = index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
	local area = pen and pen:FindFirstChild("Area")
	if not hrp or not area or (humanoid and humanoid.Sit) then
		return false
	end
	local offset = area.CFrame:PointToObjectSpace(hrp.Position)
	return math.abs(offset.X) <= area.Size.X / 2 + HOME_REACH and math.abs(offset.Z) <= area.Size.Z / 2 + HOME_REACH
end

-- How many kinds of pet you have that can fuse (hybrids can't).
local function kindsToFuse()
	local kinds, n = {}, 0
	for _, pet in yours() do
		if not pet.fuse and not kinds[pet.kind] then
			kinds[pet.kind] = true
			n += 1
		end
	end
	return n
end

Hud.onFuse = function()
	if state.active then
		stop()
	elseif not atHome() then
		flash("Fuse your pets at your pen")
		task.delay(1.6, function()
			if not state.active then
				tip.Visible = false
			end
		end)
	elseif kindsToFuse() < 2 then
		flash("You need two kinds of pets to fuse")
		task.delay(1.6, function()
			if not state.active then
				tip.Visible = false
			end
		end)
	else
		start()
	end
end

-- Leaving home (or riding off) puts picking away.
task.spawn(function()
	while true do
		if state.active and not atHome() then
			stop()
		end
		task.wait(0.3)
	end
end)
