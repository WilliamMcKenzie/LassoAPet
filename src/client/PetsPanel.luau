-- The Pets panel (QM, Oct 15): the Index's twin (Client/AnimalDex), on QM's Pets panel
-- (assets/ui/dex/PetsPanel.png), listing every pet you have, five to a row, all in colour:
-- the ones in your pen (equipped: earning) with a green outline, the ones you've taken out
-- (Hatchery's stored pets: not earning) without it and 80% opaque. Click one to take it out of
-- your pen or put it back in (UnequipPet / EquipPet; back in only while your pen has room).
--
--   PetsPanel.toggle(instant)  PetsPanel.close(instant)  PetsPanel.isOpen()
--   PetsPanel.onToggle = fn(open)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)
local Gamepad = require(script.Parent.Gamepad)
local PetFaces = require(script.Parent.PetFaces)

local player = Players.LocalPlayer

local PANEL = "rbxassetid://112260275929453" -- assets/ui/dex/PetsPanel.png (QM's, Oct 15)
local PAGE = Vector2.new(1230, 969) -- as the Index's
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the red X)
local LIST_TOP, LIST_SIDE, LIST_BOTTOM = 105, 40, 32
local PER_ROW = 5
local CELL = 200
local GAP = 16
local SELECTED = "rbxassetid://92986714288079" -- assets/ui/dex/SelectedPanel.png: behind a pet in your pen (QM, Oct 15; was a green outline)
local SCREEN_SHARE = 0.7

local PetsPanel = {}

local gui = Instance.new("ScreenGui")
gui.Name = "PetsPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1
gui.Enabled = false

local open = false
local pop = 1

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Selectable = false
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 0
backdrop.Parent = gui

local page = Instance.new("ImageLabel")
page.Name = "Page"
page.BackgroundTransparency = 1
page.AnchorPoint = Vector2.new(0.5, 0.5)
page.Position = UDim2.fromScale(0.5, 0.5)
page.Size = UDim2.fromOffset(PAGE.X, PAGE.Y)
page.Image = PANEL
page.Active = true
local scale = Instance.new("UIScale")
scale.Parent = page
page.Parent = gui

local close = Instance.new("ImageButton")
close.Name = "Close"
close.BackgroundTransparency = 1
close.Image = CLOSE
close.AnchorPoint = Vector2.new(0.5, 0.5)
close.Position = UDim2.fromOffset(PAGE.X - 9, 49 + 9) -- (on the panel's corner, as the Index's)
close.Size = UDim2.fromOffset(94, 94)
close.ZIndex = 5
close.Parent = page

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.Position = UDim2.fromOffset(LIST_SIDE, LIST_TOP)
list.Size = UDim2.fromOffset(PAGE.X - 2 * LIST_SIDE, PAGE.Y - LIST_TOP - LIST_BOTTOM)
list.ScrollBarThickness = 10
list.ScrollBarImageColor3 = Color3.new(1, 1, 1)
list.ScrollBarImageTransparency = 0.4
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.Parent = page
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(CELL, CELL)
grid.CellPadding = UDim2.fromOffset(GAP, GAP)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = list

local function decode(text)
	local ok, t = pcall(HttpService.JSONDecode, HttpService, text or "{}")
	return if ok and typeof(t) == "table" then t else {}
end

-- Each kind's rarity's place (Common 1 .. Legendary 5, Exclusive 6), from its animal module.
local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Exclusive" }
local rank = {}
local function rarityRank(kind)
	if rank[kind] == nil then
		local module = ReplicatedStorage.Shared.Animals:FindFirstChild(kind)
		local ok, class = pcall(require, module)
		rank[kind] = ok and class and table.find(RARITIES, class.Rarity) or 0
	end
	return rank[kind]
end

-- Every pet you have: { id, kind, equipped }, rarest first (QM, Oct 15: by rarity, not by
-- whether it's in your pen), then by what it earns.
local function pets()
	local out = {}
	local pen = workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. tostring(player:GetAttribute("Pen")))
	for id, item in decode(pen and pen:GetAttribute("Contents")) do
		if typeof(item) == "table" and item.pet then
			table.insert(out, { id = id, kind = item.pet, equipped = true })
		end
	end
	for id, item in decode(player:GetAttribute("StoredPets")) do
		if typeof(item) == "table" and item.pet then
			table.insert(out, { id = id, kind = item.pet, equipped = false })
		end
	end
	table.sort(out, function(a, b)
		local ra, rb = rarityRank(a.kind), rarityRank(b.kind)
		if ra ~= rb then
			return ra > rb
		end
		local ia, ib = Config.PetIncome[a.kind] or 0, Config.PetIncome[b.kind] or 0
		if ia ~= ib then
			return ia > ib
		end
		return a.id < b.id
	end)
	return out
end

local busy = false
local function fill()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for i, pet in pets() do
		local cell = Instance.new("ImageButton")
		cell.Name = pet.kind
		cell.LayoutOrder = i
		cell.AutoButtonColor = false
		cell.BackgroundTransparency = 1
		cell.Image = if pet.equipped then SELECTED else ""
		cell.ScaleType = Enum.ScaleType.Stretch
		local face = Instance.new("ImageLabel")
		face.Name = "Face"
		face.BackgroundTransparency = 1
		face.AnchorPoint = Vector2.new(0.5, 0.5)
		face.Position = UDim2.fromScale(0.5, 0.5)
		face.Size = UDim2.fromScale(0.9, 0.9)
		face.Image = PetFaces.HEADSHOTS[pet.kind] or ""
		face.ScaleType = Enum.ScaleType.Fit
		face.ImageTransparency = if pet.equipped then 0 else 0.2 -- (80% opaque out of the pen: QM)
		face.Parent = cell
		cell.Activated:Connect(function()
			if busy then
				return
			end
			busy = true
			ReplicatedStorage:WaitForChild(if pet.equipped then "UnequipPet" else "EquipPet"):FireServer(pet.id)
			task.delay(0.4, function()
				busy = false
			end)
		end)
		cell.Parent = list
	end
end

-- Kept up to date while it's open: the pen's contents and your stored pets.
local watched
local function watchPen()
	if watched then
		watched:Disconnect()
		watched = nil
	end
	local pen = workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. tostring(player:GetAttribute("Pen")))
	if pen then
		watched = pen:GetAttributeChangedSignal("Contents"):Connect(function()
			if open then
				fill()
			end
		end)
	end
end
player:GetAttributeChangedSignal("Pen"):Connect(watchPen)
watchPen()
player:GetAttributeChangedSignal("StoredPets"):Connect(function()
	if open then
		fill()
	end
end)

local camera = workspace.CurrentCamera
local function resize()
	local screen = camera.ViewportSize
	scale.Scale = math.min(screen.X * SCREEN_SHARE / PAGE.X, screen.Y * 0.85 / PAGE.Y) * pop
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
gui.Parent = player:WaitForChild("PlayerGui")

local function setPop(s)
	pop = s
	resize()
end

function PetsPanel.toggle(instant)
	open = not open
	if open then
		gui.Enabled = true
		fill()
		list.CanvasPosition = Vector2.zero
		ModalPop.open(setPop)
		Gamepad.openMenu("PetsPanel", { close = PetsPanel.close })
	else
		Gamepad.closeMenu("PetsPanel")
		ModalPop.close(setPop, function()
			gui.Enabled = false
		end, instant)
	end
	if PetsPanel.onToggle then
		PetsPanel.onToggle(open)
	end
end

function PetsPanel.isOpen()
	return open == true
end

function PetsPanel.close(instant)
	if open then
		PetsPanel.toggle(instant)
	end
end

close.Activated:Connect(function()
	PetsPanel.close()
end)
backdrop.Activated:Connect(function()
	PetsPanel.close()
end)

return PetsPanel
