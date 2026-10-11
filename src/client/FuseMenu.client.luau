-- MERGE (QM, Oct 6; the pen view, Oct 11; Shared/Fusion): the Merge button opens a
-- view of your pen from above, your animals in it, and QM's Merge panel along the
-- bottom. Click two animals and they fill its two slots; or click a slot, then the
-- animal to put in it (QM); with both full, the animal clicked takes the right slot.
-- Clicking a picked one again, or its slot, takes it out. Nothing marks the picked
-- ones in the pen but a white outline (QM, Oct 11); the one under the mouse gets a white
-- dashed ring (Outline's). While
-- it's up, the pen's eggs and everything floating over it hide (QM): the eggs, their
-- timers and the pets' plates on the "MergeView" attribute (Pen.client, PetPlates),
-- the owner's sign and every prompt here. The
-- green Merge button, its price beside the cash, shows once both are picked (grey,
-- "???", till then). Merging pulls the two up over the pen and the hybrid drops
-- down where the base was (PenPets.pull; Hatchery.server's FusePets). The left slot
-- is the base, its body and ability; the right one sets its size and paints it in
-- its colours (QM). Hybrids merge again (Fusion.combine), and so do two of the same.
--
-- The panel's laid out in pixels of QM's 996 x 378 art (assets/ui/merge/MergePenPanel.png)
-- and scaled to fit the bottom of the screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local PenPets = require(script.Parent.PenPets)
local ModalPop = require(script.Parent.ModalPop)
local Sounds = require(script.Parent.Sounds)
local Gamepad = require(script.Parent.Gamepad)
local Outline = require(script.Parent.Outline)
local TapHand = require(script.Parent.TapHand)

local Animals = ReplicatedStorage.Shared.Animals
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local PANEL = { id = "rbxassetid://87361968703172", size = Vector2.new(996, 378) } -- assets/ui/merge/MergePenPanel.png
local BUTTON = { on = "rbxassetid://77533462942727", off = "rbxassetid://88460994933250", size = Vector2.new(420, 113) } -- MergeButton.png / MergeButtonDisabled.png ("???" drawn on)
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the Index's and shop's X)
local SCREEN_SHARE = 0.52 -- the panel's share of the screen's width (QM's mockup), or less to fit
local HEIGHT_SHARE = 0.36 -- ... of its height
local SLOTS = { Rect.new(32, 147, 228, 341), Rect.new(309, 147, 505, 341) } -- the two drawn on the panel
local PILL = Vector2.new(455, 52) -- the dark strip by the title: "1/2 Selected"
local BUTTON_AT = Vector2.new(761, 246)
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local CASH_GREEN = Color3.fromHex("00FF09")
-- The camera over your pen: from its open side, looking down.
local VIEW = {
	PITCH = math.rad(58), -- down from level
	FOV = 50,
	FIT = 1.05, -- the pen's width over what's needed to fit it
	RAISE = 0.42, -- the pen's middle this far up the screen from its centre (of half its height: the panel's below)
	TIME = 0.55,
}

-- The headshot's camera (tools/pet_headshots.py, "action"): 3/4 front from a little
-- above, mid-gallop (the Snake and Starfish in their idle stance).
local YAW, PITCH, FOV = math.rad(35), math.rad(12), 26
local FACING = { Kraken = math.pi }
local ACTION_IDLE = { Snake = true, Starfish = true }

-- A pet standing still in 3D, as it is: drawn once, never redrawn (QM: unanimated).
local function still3D(kind, fuse)
	local module = Animals:FindFirstChild(kind)
	local ok, animal = pcall(function()
		return require(module).new()
	end)
	if not ok or not animal then
		return nil
	end
	animal:setSaddled(false)
	Fusion.paint(animal.model, kind, fuse)
	local gallop = animal.data and animal.data.animations and animal.data.animations.gallop
	if gallop and not ACTION_IDLE[kind] then
		animal.speed, animal.clocks.gallop = 1000, gallop.length * 0.35
		pcall(animal.update, animal, 0, 1000, 0)
	else
		pcall(animal.update, animal, 0, 0, 0)
	end
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Ambient = Color3.fromRGB(200, 200, 200)
	view.LightColor = Color3.new(1, 1, 1)
	view.LightDirection = Vector3.new(-1, -2, -1)
	local world = Instance.new("WorldModel") -- (it places the posed parts on their joints)
	world.Parent = view
	animal.model:PivotTo(CFrame.new())
	animal.model.Parent = world
	local box, extents = animal.model:GetBoundingBox()
	local yaw = YAW + (FACING[kind] or 0)
	local dir = Vector3.new(-math.sin(yaw) * math.cos(PITCH), math.sin(PITCH), -math.cos(yaw) * math.cos(PITCH))
	local radius = extents.Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = FOV
	cam.CFrame = CFrame.lookAt(box.Position + dir * radius / math.sin(math.rad(FOV) / 2) * 0.95, box.Position)
	cam.Parent = view
	view.CurrentCamera = cam
	-- Once the WorldModel has put the posed parts on their joints (a frame on), frame
	-- just what shows, as seen from the camera, so the pet sits in the middle (QM).
	task.spawn(function()
		RunService.Heartbeat:Wait()
		RunService.Heartbeat:Wait()
		if not view.Parent then
			return
		end
		local look = CFrame.lookAt(dir, Vector3.zero)
		local right, up, back = look.RightVector, look.UpVector, -look.LookVector
		local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
		local points = {}
		for _, part in animal.model:GetDescendants() do
			if part:IsA("BasePart") and part.Transparency < 1 then
				local half = part.Size / 2
				for _, corner in { Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1), Vector3.new(-1, 1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, -1, -1) } do
					local p = part.CFrame:PointToWorldSpace(half * corner) - box.Position
					local x, y = p:Dot(right), p:Dot(up)
					minX, maxX, minY, maxY = math.min(minX, x), math.max(maxX, x), math.min(minY, y), math.max(maxY, y)
					table.insert(points, Vector3.new(x, y, p:Dot(back)))
				end
			end
		end
		if #points == 0 then
			return
		end
		local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2
		local tan = math.tan(math.rad(FOV) / 2)
		local distance = 0
		for _, p in points do -- far enough back that every corner is in view
			distance = math.max(distance, math.max(math.abs(p.X - cx), math.abs(p.Y - cy)) / tan + p.Z)
		end
		local middle = box.Position + right * cx + up * cy
		cam.CFrame = CFrame.lookAt(middle + back * distance * 1.06, middle)
	end)
	return view
end

-- Your pets: the ones in the pen, and the one waiting on its spot (id "ride").
local function yourPets()
	local list = {}
	for model, pet in PenPets.pets do
		if model.Parent then
			table.insert(list, { model = model, id = pet.id, kind = pet.kind, fuse = pet.fuse, merged = pet.merged, worth = pet.worth, income = pet.income })
		end
	end
	local starter = PenPets.starter
	if starter and starter.animal.model.Parent and starter.kind == player:GetAttribute("RidePet") then
		table.insert(list, { model = starter.animal.model, id = "ride", kind = starter.kind, fuse = starter.fuse, merged = starter.merged, worth = player:GetAttribute("RideWorth"), income = player:GetAttribute("RideIncome") })
	end
	local ranks = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
	table.sort(list, function(a, b) -- rarest first, then by kind, so a kind's pets sit together
		local ra, rb = ranks[Fusion.rarity(a.kind, a.fuse)] or 0, ranks[Fusion.rarity(b.kind, b.fuse)] or 0
		if ra ~= rb then
			return ra > rb
		end
		return Fusion.key(a.kind, a.fuse) < Fusion.key(b.kind, b.fuse)
	end)
	return list
end

-- Gold to merge the two picked (QM, Oct 11: minutes of what the two earn, as the server charges).
local function priceOf(a, b)
	return Fusion.price(Fusion.earning(a.kind, a.merged, a.income) + Fusion.earning(b.kind, b.merged, b.income))
end

local function stroked(object, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = object
	return s
end

local function text(parent, size, position, textSize, anchor)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = textSize
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
	label.ZIndex = 4
	label.Parent = parent
	return label
end

local gui, panel, scale, fuseButton, priceLabel, pill, tip
local pop = 1
local open = false
local pets = {} -- this opening's: { model, id, kind, fuse, merged, worth, income }
local slots = {} -- [1], [2]: the pet in each (either may be nil)
local active -- the slot clicked last, empty, that the next animal clicked goes in
local slotUi = {} -- [i] = { button, frame (the outline), view, name, hint }
local marks = {} -- [pet] = its white outline (a Highlight): the picked ones
local hover = Outline.circle() -- the white dashed ring round the animal under the mouse
local hovered -- its model
local savedView -- the camera as it was: { type, cframe, fov }
local viewAt -- the pen view's CFrame while it's open
local blend = 0 -- 0: the camera as it was, 1: the pen view (eased in and out)

local function pickedCount()
	return (if slots[1] then 1 else 0) + (if slots[2] then 1 else 0)
end

local function slotOf(pet)
	return if slots[1] == pet then 1 elseif slots[2] == pet then 2 else nil
end

-- A picked animal gets a white outline in the pen (QM, Oct 11: nothing else, the rest
-- was too noisy). A Highlight, which the game otherwise avoids (it hitches on phones),
-- but only ever these two and only while the menu's up (QM: "if it lags i will undo it").
local function mark(pet)
	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.new(1, 1, 1)
	outline.OutlineTransparency = 0
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Adornee = pet.model
	outline.Parent = gui
	marks[pet] = outline
end

local function unmark(pet)
	if marks[pet] then
		marks[pet]:Destroy()
		marks[pet] = nil
	end
end

local function refresh()
	for i = 1, 2 do
		local ui, pet = slotUi[i], slots[i]
		-- (its 3D picture is made again only when the pet in it changes: refresh runs
		-- every time your cash ticks up, and remaking it each time made it flash: QM)
		local changed = ui.shown ~= pet
		ui.shown = pet
		if changed and ui.view then
			ui.view:Destroy()
			ui.view = nil
		end
		if changed and pet then
			local view = still3D(pet.kind, pet.fuse)
			if view then
				view.AnchorPoint = Vector2.new(0.5, 0.5)
				view.Position = UDim2.fromScale(0.5, 0.44)
				view.Size = UDim2.fromScale(0.82, 0.82)
				view.ZIndex = 3
				view.Parent = ui.button
				ui.view = view
			end
		end
		ui.name.Text = if pet then Fusion.name(pet.kind, pet.fuse) else ""
		ui.hint.Visible = pet == nil
		ui.frame.Enabled = active == i and pet == nil
	end
	local count = pickedCount()
	pill.Text = count .. "/2 Selected"
	local ready = count == 2
	local lesson = player:GetAttribute("FuseLesson") == true -- (the fuse lesson's merge is free: QM)
	local price = if ready and not lesson then priceOf(slots[1], slots[2]) else 0
	fuseButton.Image = if ready then BUTTON.on else BUTTON.off
	priceLabel.Visible = ready
	priceLabel.Text = if lesson then "FREE" else Hud.money(price)
	priceLabel.TextColor3 = if lesson or (player:GetAttribute("Gold") or 0) >= price then CASH_GREEN else Color3.fromRGB(255, 70, 70)
	if ready and not fuseButton:GetAttribute("Ready") then -- a pop once it's ready
		local s = fuseButton:FindFirstChildOfClass("UIScale")
		s.Scale = 0.85
		TweenService:Create(s, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	fuseButton:SetAttribute("Ready", ready)
end

-- Clicking an animal: out if it's in, else into the slot you clicked, or the first free one.
local function pickAnimal(pet)
	local i = slotOf(pet)
	if i then
		slots[i] = nil
		unmark(pet)
	else
		local into = if active and not slots[active] then active elseif not slots[1] then 1 elseif not slots[2] then 2 else 2
		if slots[into] then -- (both full: it takes the right one's place)
			unmark(slots[into])
		end
		slots[into] = pet
		active = nil
		if hovered == pet.model then
			hovered = nil
			hover:hide()
		end
		mark(pet)
		Sounds.play("merge_pop")
	end
	refresh()
end

-- Clicking a slot: a full one empties; an empty one waits for the animal you click.
local function clickSlot(i)
	if slots[i] then
		unmark(slots[i])
		slots[i] = nil
		active = nil
	else
		active = if active == i then nil else i
	end
	Sounds.play("button_click")
	refresh()
end

-- The animal at a point on the screen, if any: the one whose blocks are under it (see-
-- through parts, like a big animal's hit box, don't count), else the one drawn
-- nearest it if it's close (the pet waiting on its spot isn't clickable by ray, and
-- a small one's easily missed). Of several close, the smallest on screen wins.
local PICK_SLACK = 14 -- pixels past an animal's drawn size that still count
local function petAt(point)
	local models, byModel = {}, {}
	for _, pet in pets do
		if pet.model.Parent then
			table.insert(models, pet.model)
			byModel[pet.model] = pet
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = models
	-- (input positions are below Roblox's top bar, the GUI inset: ScreenPointToRay and
	-- WorldToScreenPoint allow for it, the Viewport ones don't, and picks came out off)
	local ray = camera:ScreenPointToRay(point.X, point.Y)
	local origin = ray.Origin
	for _ = 1, 8 do
		local hit = workspace:Raycast(origin, ray.Direction * 600, params)
		if not hit then
			break
		end
		if hit.Instance.Transparency < 0.95 then
			for model, pet in byModel do
				if hit.Instance:IsDescendantOf(model) then
					return pet
				end
			end
			break
		end
		origin = hit.Position + ray.Direction * 0.05 -- (see-through: on past it)
	end
	local best, bestRadius = nil, math.huge
	local focal = camera.ViewportSize.Y / 2 / math.tan(math.rad(camera.FieldOfView) / 2)
	for model, pet in byModel do
		local cf, size = model:GetBoundingBox()
		local at, onScreen = camera:WorldToScreenPoint(cf.Position)
		if onScreen and at.Z > 0 then
			local radius = math.max(size.X, size.Y, size.Z) * 0.45 * focal / at.Z
			if (Vector2.new(at.X, at.Y) - point).Magnitude <= radius + PICK_SLACK and radius < bestRadius then
				best, bestRadius = pet, radius
			end
		end
	end
	return best
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not open or processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pet = petAt(Vector2.new(input.Position.X, input.Position.Y))
		if pet then
			pickAnimal(pet)
		end
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not open or input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	local pet = petAt(Vector2.new(input.Position.X, input.Position.Y))
	local model = if pet and not marks[pet] then pet.model else nil
	if model ~= hovered then
		hovered = model
		if model and model.PrimaryPart then
			hover:fit(model, model.PrimaryPart)
		else
			hover:hide()
		end
	end
end)

-- The camera over your pen, from its open side (where you come in), looking down.
local function penView()
	local index = player:GetAttribute("Pen")
	local pen = index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
	local area = pen and pen:FindFirstChild("Area")
	if not area then
		return nil
	end
	local middle = area.Position - Vector3.new(0, area.Size.Y / 2, 0)
	local spawn = pen:FindFirstChild("Spawn")
	local into = if spawn then (middle - spawn.Position) * Vector3.new(1, 0, 1) else area.CFrame.LookVector * Vector3.new(1, 0, 1)
	into = if into.Magnitude > 0.01 then into.Unit else Vector3.new(0, 0, -1)
	local look = into * math.cos(VIEW.PITCH) - Vector3.new(0, math.sin(VIEW.PITCH), 0)
	local half = math.max(area.Size.X, area.Size.Z) / 2 * VIEW.FIT
	local aspect = camera.ViewportSize.X / math.max(camera.ViewportSize.Y, 1)
	local tanV = math.tan(math.rad(VIEW.FOV) / 2)
	local distance = half / (tanV * aspect) -- (wide enough across)
	distance = math.max(distance, half * math.sin(VIEW.PITCH) / (tanV * (1 - VIEW.RAISE)) + half * math.cos(VIEW.PITCH)) -- (and down)
	local from = middle - look * distance
	-- Turned down a touch, so the pen sits above the panel.
	return CFrame.lookAt(from, middle) * CFrame.Angles(-math.atan(tanV * VIEW.RAISE), 0, 0)
end

-- Everything floating over the pen hides while it's up (QM): the eggs, their timers and
-- the pets' plates go on MergeView (Pen.client, PetPlates); the owner's sign and the
-- prompts (RIDE, the eggs') here.
local ProximityPromptService = game:GetService("ProximityPromptService")
local hiddenSigns = {}
local function hideOverPen(on)
	player:SetAttribute("MergeView", on)
	ProximityPromptService.Enabled = not on
	if on then
		local index = player:GetAttribute("Pen")
		local pen = index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
		for _, d in if pen then pen:GetDescendants() else {} do
			if d:IsA("BillboardGui") and d.Enabled then
				d.Enabled = false
				table.insert(hiddenSigns, d)
			end
		end
	else
		for _, d in hiddenSigns do
			d.Enabled = true
		end
		table.clear(hiddenSigns)
	end
end

local function sinkMoves()
	return Enum.ContextActionResult.Sink
end

local function setPop(s)
	pop = s
	local screen = camera.ViewportSize
	scale.Scale = math.min(screen.X * SCREEN_SHARE / PANEL.size.X, screen.Y * HEIGHT_SHARE / PANEL.size.Y) * pop
end

local close

local function showTip(message)
	tip.Text = message
	tip.Visible = true
	task.delay(1.6, function()
		tip.Visible = false
	end)
end

local function fuse()
	local a, b = slots[1], slots[2]
	if not a or not b then
		showTip("Pick two animals to merge")
		return
	end
	if not player:GetAttribute("FuseLesson") and (player:GetAttribute("Gold") or 0) < priceOf(a, b) then
		showTip("Not enough cash")
		return
	end
	local base, donor, aIsBase = Fusion.combine(a.kind, a.fuse, b.kind, b.fuse)
	if not base then
		return
	end
	local baseModel = if aIsBase then a.model else b.model
	-- The two are pulled up over the base and merge, as a merge's are; the hybrid
	-- drops down from there (Pen.client, or Ride.client's starter).
	if baseModel.Parent then
		local index = player:GetAttribute("Pen")
		local pen = index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
		local area = pen and pen:FindFirstChild("Area")
		local spot = baseModel:GetPivot().Position
		local floor = if area then area.Position.Y - area.Size.Y / 2 else spot.Y
		local up = Vector3.new(spot.X, floor + PenPets.MERGE_UP, spot.Z)
		PenPets.merges[Fusion.key(base, donor)] = { at = up, landAt = os.clock() + PenPets.MERGE_PULL }
		if PenPets.pull then
			PenPets.pull({ a.model, b.model }, up)
		end
	end
	ReplicatedStorage:WaitForChild("FusePets"):FireServer(a.id, b.id)
	Hud.fusedAt = os.clock() -- (Tutorial waits for it)
	player:SetAttribute("MergeHint", nil) -- (the quest's hint: done)
	-- (the view stays a moment, so you see them merge)
	for pet in marks do
		unmark(pet)
	end
	slots[1], slots[2] = nil, nil
	refresh()
	-- It stays open (QM, Oct 11: keep merging): once the merge has landed, the list
	-- picks up the merged pet and loses the two that went into it.
	for _, after in { 1.6, 3 } do -- (and again, in case the server's pen update came late)
		task.delay(after, function()
			if open then
				pets = yourPets()
				refresh()
			end
		end)
	end
end

local function openPage()
	local view = penView()
	if not view then
		return false
	end
	pets = yourPets()
	open = true
	slots[1], slots[2], active = nil, nil, nil
	gui.Enabled = true
	refresh()
	tip.Visible = false
	if not savedView then
		savedView = { type = camera.CameraType, cframe = camera.CFrame, fov = camera.FieldOfView }
	end
	viewAt = view
	hideOverPen(true)
	ContextActionService:BindActionAtPriority("MergeViewStill", sinkMoves, false, Enum.ContextActionPriority.High.Value + 1,
		Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
	ModalPop.open(setPop)
	Gamepad.openMenu("Fuse", { close = close })
	Hud.fuseToggled(true)
	return true
end

function close(instant)
	if not open then
		return
	end
	open = false
	hovered = nil
	hover:hide()
	hideOverPen(false)
	player:SetAttribute("MergeHint", nil)
	for pet in marks do
		unmark(pet)
	end
	slots[1], slots[2], active = nil, nil, nil
	ContextActionService:UnbindAction("MergeViewStill")
	if instant then
		blend = 0
	end
	Gamepad.closeMenu("Fuse")
	ModalPop.close(setPop, function()
		gui.Enabled = false
	end, instant)
	Hud.fuseToggled(false)
end

-- The camera: eased over to the pen view while it's open and back again after, held
-- there every frame (nothing else gets to move it meanwhile).
RunService:BindToRenderStep("MergeView", Enum.RenderPriority.Camera.Value + 2, function(dt)
	if not savedView then
		return
	end
	blend = math.clamp(blend + (if open then dt else -dt) / VIEW.TIME, 0, 1)
	if blend <= 0 and not open then
		camera.CameraType = savedView.type
		camera.FieldOfView = savedView.fov
		savedView = nil
		return
	end
	local e = blend * blend * (3 - 2 * blend)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = savedView.cframe:Lerp(viewAt, e)
	camera.FieldOfView = savedView.fov + (VIEW.FOV - savedView.fov) * e
end)

-- QM's panel along the bottom of the screen.
gui = Instance.new("ScreenGui")
gui.Name = "FuseMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- under the HUD
gui.Enabled = false
panel = Instance.new("ImageLabel")
panel.Name = "Panel"
panel.BackgroundTransparency = 1
panel.Image = PANEL.id
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -16)
panel.Size = UDim2.fromOffset(PANEL.size.X, PANEL.size.Y)
scale = Instance.new("UIScale")
scale.Parent = panel
panel.Parent = gui

pill = text(panel, UDim2.fromOffset(236, 62), UDim2.fromOffset(PILL.X, PILL.Y), 30)

for i, rect in SLOTS do
	local button = Instance.new("TextButton")
	button.Name = "Slot" .. i
	button.Text = ""
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Position = UDim2.fromOffset(rect.Min.X, rect.Min.Y)
	button.Size = UDim2.fromOffset(rect.Width, rect.Height)
	button.ZIndex = 2
	local frame = Instance.new("UIStroke") -- (waiting for an animal: QM's "click the slot, then the animal")
	frame.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frame.Color = Color3.new(1, 1, 1)
	frame.Thickness = 5
	frame.Enabled = false
	frame.Parent = button
	Instance.new("UICorner", button).CornerRadius = UDim.new(0.1, 0)
	local name = text(button, UDim2.new(1, -12, 0, 40), UDim2.new(0.5, 0, 1, -24), 32)
	name.TextScaled = true
	Instance.new("UITextSizeConstraint", name).MaxTextSize = 32
	name.ZIndex = 5
	stroked(name, 4)
	local hint = text(button, UDim2.fromScale(1, 0.3), UDim2.fromScale(0.5, 0.5), 36)
	hint.Text = "Select"
	button.Activated:Connect(function()
		clickSlot(i)
	end)
	button.Parent = panel
	slotUi[i] = { button = button, frame = frame, name = name, hint = hint }
end

fuseButton = Instance.new("ImageButton")
fuseButton.Name = "Merge"
fuseButton.BackgroundTransparency = 1
fuseButton.AutoButtonColor = false
fuseButton.Image = BUTTON.off
fuseButton.AnchorPoint = Vector2.new(0.5, 0.5)
fuseButton.Size = UDim2.fromOffset(BUTTON.size.X, BUTTON.size.Y)
fuseButton.Position = UDim2.fromOffset(BUTTON_AT.X, BUTTON_AT.Y)
fuseButton.ZIndex = 5
Instance.new("UIScale").Parent = fuseButton
fuseButton.Activated:Connect(fuse)
fuseButton.Parent = panel
-- The price, beside the drawn cash, where and as big as the grey button's "???" (QM).
priceLabel = text(fuseButton, UDim2.fromOffset(158, 64), UDim2.fromOffset(83, 57), 48, Vector2.new(0, 0.5)) -- (48, not scaled: QM)
priceLabel.TextXAlignment = Enum.TextXAlignment.Left
priceLabel.ZIndex = 6
stroked(priceLabel, 5)
for _, name in { "Gold", "FuseLesson" } do
	player:GetAttributeChangedSignal(name):Connect(function()
		if open then
			refresh()
		end
	end)
end

-- The X, on the panel's top right corner.
local closeButton = Instance.new("ImageButton")
closeButton.Name = "Close"
closeButton.BackgroundTransparency = 1
closeButton.AutoButtonColor = false
closeButton.Image = CLOSE
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Position = UDim2.fromOffset(PANEL.size.X - 14, 58)
closeButton.Size = UDim2.fromOffset(84, 84)
closeButton.ZIndex = 6
closeButton.Activated:Connect(function()
	close()
end)
closeButton.Parent = panel

tip = text(panel, UDim2.fromOffset(600, 50), UDim2.fromOffset(PANEL.size.X / 2, -40), 40)
tip.ZIndex = 6
tip.Visible = false
stroked(tip, 4)

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	setPop(pop)
end)
setPop(1)
gui.Parent = player:WaitForChild("PlayerGui")

-- The Merge button: opens the view, or closes it again.
Hud.onFuse = function()
	if open then
		close()
	else
		openPage()
	end
end
Hud.closeFuse = close

-- (Studio only, for trying it out from the command bar: the LocalPlayer's MergeTest
-- attribute "open", "close", a number to click that animal, "slot1" / "slot2", or a
-- Vector2 to click that point on the screen, as an input's Position.)
if RunService:IsStudio() then
	player:GetAttributeChangedSignal("MergeTest"):Connect(function()
		local v = player:GetAttribute("MergeTest")
		if v == "open" and not open then
			openPage()
		elseif v == "close" then
			close()
		elseif v == "slot1" or v == "slot2" then
			clickSlot(if v == "slot1" then 1 else 2)
		elseif typeof(v) == "number" and pets[v] then
			pickAnimal(pets[v])
		elseif typeof(v) == "Vector2" then
			local pet = petAt(v)
			player:SetAttribute("MergeTestHit", if pet then pet.kind else "none")
			if pet then
				pickAnimal(pet)
			end
		end
	end)
end

-- The "Merge animals" quest's hint (BaseUi sets "MergeHint"; QM, Oct 11): tap hands
-- on two animals to pick, then on the Merge button once both are.
local hintHands = { TapHand.new(80), TapHand.new(80), TapHand.new(80) }
for _, hand in hintHands do
	hand.Visible = false
	hand.Parent = gui
end
RunService.RenderStepped:Connect(function()
	local on = open and player:GetAttribute("MergeHint") == true
	local shown = 0
	local size = camera.ViewportSize.Y * 0.1
	for _, hand in hintHands do
		hand.Size = UDim2.fromOffset(math.round(size * 488 / 610), size)
	end
	if on and pickedCount() == 2 then
		local at = fuseButton.AbsolutePosition + fuseButton.AbsoluteSize * Vector2.new(0.55, 0.7)
		hintHands[3].Position = UDim2.fromOffset(at.X, at.Y)
		hintHands[3].Visible = true
	else
		hintHands[3].Visible = false
		for _, pet in (if on then pets else {}) do
			if shown >= 2 - pickedCount() then
				break
			end
			if not slotOf(pet) and pet.model.Parent then
				local point, visible = camera:WorldToViewportPoint(pet.model:GetPivot().Position)
				if visible then
					shown += 1
					hintHands[shown].Position = UDim2.fromOffset(point.X, point.Y)
				end
			end
		end
	end
	for i = 1, 2 do
		hintHands[i].Visible = i <= shown
	end
end)

-- Riding off closes it.
player.CharacterAdded:Connect(function()
	close(true)
end)
task.spawn(function()
	while true do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if open and humanoid and humanoid.Sit then
			close(true)
		end
		task.wait(0.3)
	end
end)
