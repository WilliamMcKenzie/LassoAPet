-- FUSE (QM, Oct 6; Shared/Fusion): the Fuse button (Hud's, under Pets) opens QM's
-- FUSION panel: your pets on the dictionary's rarity cards, 8 to a page (arrows
-- for more), each still in 3D as it is (merged bigger, a hybrid in its colours).
-- Tap two to pick them (each gets an outline); their names show in the strip at the
-- bottom either side of QM's FUSE button ("???" till picked), with the price over
-- it. FUSE closes the panel and the two are pulled up over the pen and fuse, as merging does (PenPets.pull), and the
-- hybrid drops down where the base was (Hatchery.server's FusePets). The left pick
-- (the first) is the base, its body and ability; the right one sets its size and
-- paints it in its colours (QM). Hybrids fuse
-- again (QM; Fusion.combine), and two of the same pet merge instead (MERGE). No
-- hybrid names anywhere (QM): a hybrid's card has none, the strip says its base.
--
-- Laid out in pixels of QM's 1102 x 829 panel (assets/ui/fuse/FusionPanel.png) and
-- scaled to fit the screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Hud = require(script.Parent.Hud)
local PenPets = require(script.Parent.PenPets)
local ModalPop = require(script.Parent.ModalPop)
local Sounds = require(script.Parent.Sounds)
local Gamepad = require(script.Parent.Gamepad)

local Animals = ReplicatedStorage.Shared.Animals
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local PAGE = Vector2.new(1102, 829)
local SCREEN_SHARE = 0.54 -- as the dictionary's
local CARD, ART = 200, 180 -- the dictionary's grid: 200 px cards, the pet 180 px in the middle
local COLUMNS, ROWS = 4, 2 -- 8 to a page (QM)
local INSIDE = Rect.new(6, 43, 1096, 609) -- the panel's blue, down to the top of FUSE
local STRIP_Y = 756 -- the middle of the strip along the bottom
local BUTTON = Vector2.new(278, 189) -- QM's FUSE button (assets/ui/fuse/FuseButton.png)
local BUTTON_Y = 698 -- its middle, over the strip's top edge (QM's mockup)
-- The same space round every card and between them (QM: even margins), across and down.
local GAP_X = (INSIDE.Width - COLUMNS * CARD) / (COLUMNS + 1)
local GAP_Y = (INSIDE.Height - ROWS * CARD) / (ROWS + 1)
local CARD_CORNER = UDim.new(0.05, 0) -- the rarity cards' own corners (10 px of 200), or the clip cuts their edge
local FONT = Enum.Font.FredokaOne
local PAGE_ART = "rbxassetid://132460179762796" -- assets/ui/fuse/FusionPanel.png (QM)
local BUTTON_ART = "rbxassetid://92820434532680" -- assets/ui/fuse/FuseButton.png (QM)
local CARDS = { -- the dictionary's rarity cards (assets/ui/dex/Dex<Rarity>.png)
	Common = "rbxassetid://79697917998703",
	Uncommon = "rbxassetid://129147449223279",
	Rare = "rbxassetid://72145821537095",
	Epic = "rbxassetid://137693950544184",
	Legendary = "rbxassetid://80504921595928",
}
local ARROW = "rbxassetid://130844925944438" -- assets/ui/dex/DexArrow.png (points up)
local ARROW_Y = 340 -- beside the cards (QM's mockup)
local kept = {} -- the panel's own parts, kept when a page's cards are cleared
local PICKED = Color3.new(1, 1, 1) -- the outline on a picked pet (QM: white)

local gui, page, scale
local pop = 1
local open = false
local pets = {} -- this opening's: { model, id, kind, fuse, merged }
local picks = {} -- up to two of `pets`
local at = 1 -- the first pet on the page shown
local cards = {} -- [pet] = its card
local fuseButton, tip, nameA, nameB, priceLabel

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

-- Gold to fuse the two picked (QM: each pet adds its rarity's price).
local function priceOf(a, b)
	return Fusion.price(a.kind, b.kind)
end

local function rarityOf(kind)
	local ok, class = pcall(require, Animals:FindFirstChild(kind))
	return ok and class and class.Rarity or "Common"
end

local function stroked(object, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
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
	label.ZIndex = 4
	stroked(label, 3)
	label.Parent = parent
	return label
end

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
			table.insert(list, { model = model, id = pet.id, kind = pet.kind, fuse = pet.fuse, merged = pet.merged })
		end
	end
	local starter = PenPets.starter
	if starter and starter.animal.model.Parent and starter.kind == player:GetAttribute("RidePet") then
		table.insert(list, { model = starter.animal.model, id = "ride", kind = starter.kind, fuse = starter.fuse, merged = starter.merged })
	end
	local ranks = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
	table.sort(list, function(a, b) -- rarest first, then by kind, so a kind's pets sit together
		local ra, rb = ranks[rarityOf(a.kind)] or 0, ranks[rarityOf(b.kind)] or 0
		if ra ~= rb then
			return ra > rb
		end
		return Fusion.key(a.kind, a.fuse) < Fusion.key(b.kind, b.fuse)
	end)
	return list
end

-- Whether `pet` can go with what's picked (Fusion.combine): two of the same pet
-- merge instead.
local function canPick(pet)
	local other = picks[1]
	return not other or other == pet or Fusion.combine(other.kind, other.fuse, pet.kind, pet.fuse) ~= nil
end

local showPage

local function refresh()
	for pet, card in cards do
		local picked = table.find(picks, pet) ~= nil
		card.Outline.Enabled = picked
		card.UIScale.Scale = if picked then 1.06 else 1
		local dim = not picked and #picks >= 1 and not canPick(pet)
		card.ImageTransparency = if dim then 0.5 else 0
		card.Art.GroupTransparency = if dim then 0.5 else 0
	end
	-- The strip: the picks' names either side of FUSE, "???" till picked.
	nameA.Text = if picks[1] then Fusion.name(picks[1].kind) else "???"
	nameB.Text = if picks[2] then Fusion.name(picks[2].kind) else "???"
	local ready = #picks == 2
	local price = ready and priceOf(picks[1], picks[2])
	priceLabel.Visible = ready and price > 0 -- (no price shown while fusing's free)
	priceLabel.Text = if price then money(price) else ""
	local can = ready and (player:GetAttribute("Gold") or 0) >= price
	fuseButton.ImageColor3 = if can then Color3.new(1, 1, 1) else Color3.fromRGB(150, 150, 150)
	if ready and not fuseButton:GetAttribute("Ready") then -- a pop once it's ready
		local s = fuseButton:FindFirstChildOfClass("UIScale")
		s.Scale = 0.85
		TweenService:Create(s, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	fuseButton:SetAttribute("Ready", ready)
end

local function toggle(pet)
	local i = table.find(picks, pet)
	if i then
		table.remove(picks, i)
	elseif canPick(pet) and #picks < 2 then
		table.insert(picks, pet)
		Sounds.play("merge_pop")
	else
		tip.Text = "Pick a different animal"
		tip.Visible = true
		task.delay(1.6, function()
			tip.Visible = false
		end)
		return
	end
	refresh()
end

local function arrow(position, turn, onClick)
	local a = Instance.new("ImageButton")
	a.BackgroundTransparency = 1
	a.AutoButtonColor = false
	a.Image = ARROW
	a.Rotation = turn
	a.AnchorPoint = Vector2.new(0.5, 0.5)
	a.Size = UDim2.fromOffset(140, 140)
	a.Position = position
	a.ZIndex = 3
	a.Activated:Connect(onClick)
	a.Parent = page
	return a
end

-- One page of up to 12 cards, with arrows to the pages either side.
function showPage(first)
	at = first
	for _, child in page:GetChildren() do
		if child:IsA("GuiObject") and not kept[child] then
			child:Destroy()
		end
	end
	table.clear(cards)
	local perPage = COLUMNS * ROWS
	if first > 1 then
		arrow(UDim2.fromOffset(-100, ARROW_Y), -90, function()
			Sounds.play("book_flip")
			showPage(first - perPage)
		end)
	end
	if first + perPage <= #pets then
		arrow(UDim2.fromOffset(PAGE.X + 100, ARROW_Y), 90, function()
			Sounds.play("book_flip")
			showPage(first + perPage)
		end)
	end
	for i = first, math.min(first + perPage - 1, #pets) do
		local pet = pets[i]
		local slot = i - first
		local col, row = slot % COLUMNS, slot // COLUMNS
		local card = Instance.new("ImageButton")
		card.Name = pet.kind
		card.BackgroundTransparency = 1
		card.AutoButtonColor = false
		card.Image = CARDS[rarityOf(pet.kind)] or CARDS.Common
		card.Size = UDim2.fromOffset(CARD, CARD)
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.fromOffset(
			INSIDE.Min.X + GAP_X + col * (CARD + GAP_X) + CARD / 2,
			INSIDE.Min.Y + GAP_Y + row * (CARD + GAP_Y) + CARD / 2
		)
		Instance.new("UIScale").Parent = card
		local corner = Instance.new("UICorner")
		corner.CornerRadius = CARD_CORNER
		corner.Parent = card
		local outline = Instance.new("UIStroke") -- picked (QM: choosing a pet outlines it)
		outline.Name = "Outline"
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outline.Thickness = 8
		outline.Color = PICKED
		outline.Enabled = false
		outline.Parent = card
		local art = Instance.new("CanvasGroup") -- (fades with the card when it can't be picked)
		art.Name = "Art"
		art.BackgroundTransparency = 1
		art.AnchorPoint = Vector2.new(0.5, 0.5)
		art.Position = UDim2.fromScale(0.5, 0.5)
		art.Size = UDim2.fromOffset(ART, ART)
		art.Parent = card
		local view = still3D(pet.kind, pet.fuse)
		if view then
			view.Size = UDim2.fromScale(1, 1)
			view.Parent = art
		end
		if not pet.fuse and (pet.merged or 1) > 1 then -- how many it's merged from (no names: QM)
			local tag = text(card, UDim2.new(1, 0, 0, 30), UDim2.new(0.5, 0, 1, -14), 26)
			tag.Text = "x" .. pet.merged
		end
		card.Activated:Connect(function()
			toggle(pet)
		end)
		card.Parent = page
		cards[pet] = card
	end
	refresh()
end

local function setPop(s)
	pop = s
	local screen = camera.ViewportSize
	scale.Scale = math.min(screen.X * SCREEN_SHARE / PAGE.X, screen.Y * 0.8 / PAGE.Y) * pop
end

local close

local function fuse()
	local a, b = picks[1], picks[2]
	if not a or not b then
		tip.Text = "Pick two pets to fuse"
		tip.Visible = true
		task.delay(1.6, function()
			tip.Visible = false
		end)
		return
	end
	if (player:GetAttribute("Gold") or 0) < priceOf(a, b) then
		tip.Text = "Not enough gold"
		tip.Visible = true
		task.delay(1.6, function()
			tip.Visible = false
		end)
		return
	end
	local base, donor, aIsBase = Fusion.combine(a.kind, a.fuse, b.kind, b.fuse)
	if not base then
		return
	end
	local baseModel = if aIsBase then a.model else b.model
	-- The two are pulled up over the base and fuse, as a merge's are; the hybrid
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
	close()
end

local function openPage()
	pets = yourPets()
	local kinds, n = {}, 0
	for _, pet in pets do
		local key = Fusion.key(pet.kind, pet.fuse)
		if not kinds[key] then
			kinds[key], n = true, n + 1
		end
	end
	open = true
	table.clear(picks)
	gui.Enabled = true
	showPage(1)
	-- (It opens all the same: the page says what's missing. It used to say so on the
	-- screen instead, on this hidden ScreenGui, so Fuse seemed to do nothing.)
	tip.Text = "You need two kinds of pets to fuse"
	tip.Visible = n < 2
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
	Gamepad.closeMenu("Fuse")
	ModalPop.close(setPop, function()
		gui.Enabled = false
		table.clear(cards)
		for _, child in page:GetChildren() do
			if child:IsA("GuiObject") and not kept[child] then
				child:Destroy()
			end
		end
	end, instant)
	Hud.fuseToggled(false)
end

-- The page in the middle of the screen, as the dictionary's; clicking off it closes it.
gui = Instance.new("ScreenGui")
gui.Name = "FuseMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- under the HUD, so the Fuse button that closes it stays on top
gui.Enabled = false
local function over(object, point)
	local min, size = object.AbsolutePosition, object.AbsoluteSize
	return point.X >= min.X and point.Y >= min.Y and point.X <= min.X + size.X and point.Y <= min.Y + size.Y
end
local backdrop = Instance.new("TextButton")
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Selectable = false
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 0
backdrop.Activated:Connect(function(input)
	local point = Vector2.new(input.Position.X, input.Position.Y)
	if over(page, point) then
		return
	end
	for _, d in page:GetDescendants() do
		if d:IsA("GuiButton") and d.Visible and over(d, point) then
			return
		end
	end
	close()
end)
backdrop.Parent = gui
page = Instance.new("ImageLabel")
page.Name = "Page"
page.BackgroundTransparency = 1
page.Image = PAGE_ART
page.AnchorPoint = Vector2.new(0.5, 0.5)
page.Position = UDim2.fromScale(0.5, 0.5)
page.Size = UDim2.fromOffset(PAGE.X, PAGE.Y)
scale = Instance.new("UIScale")
scale.Parent = page
page.Parent = gui

-- QM's FUSE button over the strip, greyed till two are picked (and you can pay),
-- the price over it; the picks' names either side.
fuseButton = Instance.new("ImageButton")
fuseButton.Name = "Fuse"
fuseButton.BackgroundTransparency = 1
fuseButton.AutoButtonColor = false
fuseButton.Image = BUTTON_ART
fuseButton.AnchorPoint = Vector2.new(0.5, 0.5)
fuseButton.Size = UDim2.fromOffset(BUTTON.X, BUTTON.Y)
fuseButton.Position = UDim2.fromOffset(PAGE.X / 2, BUTTON_Y)
fuseButton.ZIndex = 5
Instance.new("UIScale").Parent = fuseButton
fuseButton.Activated:Connect(fuse)
fuseButton.Parent = page
priceLabel = text(page, UDim2.fromOffset(400, 40), UDim2.fromOffset(PAGE.X / 2, BUTTON_Y - BUTTON.Y / 2 - 22), 36)
priceLabel.ZIndex = 6
local side = (PAGE.X - BUTTON.X) / 2 -- the strip either side of FUSE
nameA = text(page, UDim2.fromOffset(side - 40, 70), UDim2.fromOffset(side / 2, STRIP_Y), 56)
nameB = text(page, UDim2.fromOffset(side - 40, 70), UDim2.fromOffset(PAGE.X - side / 2, STRIP_Y), 56)
for _, label in { nameA, nameB } do
	label.TextScaled = true -- (a long name fits)
	Instance.new("UITextSizeConstraint", label).MaxTextSize = 56
end
tip = text(page, UDim2.fromOffset(700, 50), UDim2.fromOffset(PAGE.X / 2, (INSIDE.Min.Y + INSIDE.Max.Y) / 2), 40)
tip.ZIndex = 6
tip.Visible = false
for _, object in { fuseButton, priceLabel, nameA, nameB, tip } do
	kept[object] = true
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	setPop(pop)
end)
setPop(1)
gui.Parent = player:WaitForChild("PlayerGui")

-- The Fuse button: opens the page, or closes it again.
Hud.onFuse = function()
	if open then
		close()
	else
		openPage()
	end
end
Hud.closeFuse = close

-- The tutorial's fuse step (Tutorial): what to click next while the page is open,
-- the next pet to pick or else FUSE (and true); nil while it's shut, false if
-- there's no pet on the page it can pick.
Hud.fuseGuide = function()
	if not open then
		return nil
	elseif #picks >= 2 then
		return fuseButton, true
	end
	for _, pet in pets do
		if cards[pet] and not table.find(picks, pet) and canPick(pet) then
			return cards[pet]
		end
	end
	return if picks[1] then cards[picks[1]] else false -- (clicking it unpicks it)
end

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
