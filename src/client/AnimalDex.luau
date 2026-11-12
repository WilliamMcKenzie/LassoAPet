-- The Index (QM, Oct 15: "completely different ... very simple", the old book of pages scrapped):
-- QM's panel (assets/ui/dex/IndexPanel2.png, "Index" and its book on the top edge) with every
-- animal of this world's biomes, biome by biome under its name (Fredoka One), five to a row:
-- each one's headshot (PetFaces) in colour once you've had it as a pet (hatched, or brought
-- home from a ride), a black silhouette until then (the "Caught" attribute, Hatchery.server). Per world: only
-- this world's biomes and the animals in their herds (QM). Its X, or a click off it, closes it.
--
--   AnimalDex.toggle(instant)     -- the Index button
--   AnimalDex.close(instant)      -- instant: no closing animation (switching menus)
--   AnimalDex.isOpen()
--   AnimalDex.onToggle = fn(open) -- set by the HUD

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)
local Gamepad = require(script.Parent.Gamepad)
local PetFaces = require(script.Parent.PetFaces)

local player = Players.LocalPlayer

local PANEL = "rbxassetid://72280371381048" -- assets/ui/dex/IndexPanel2.png (QM's, Oct 15)
local PAGE = Vector2.new(1230, 969) -- the panel's own pixels: everything below is laid out in them
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the red X)
local LIST_TOP, LIST_SIDE, LIST_BOTTOM = 105, 40, 32 -- the scrolling list's inset in the panel
local PER_ROW = 5
local CELL = 200 -- each animal's square
local GAP = 16
local HEADER = 56 -- a biome name's height (QM, Oct 15: 20% smaller, was 70)
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local SCREEN_SHARE = 0.7 -- of the screen's width, at most (and 85% of its height)

local AnimalDex = {}

-- This world's biomes, each with its animals: the herd's (and its 1-in-1,000 trophies), cheapest
-- first.
local BIOMES = {}
for i, biome in Config.Biomes do
	local kinds = {}
	for kind, weight in biome.Herd or {} do
		if weight > 0 and PetFaces.HEADSHOTS[kind] ~= nil then
			table.insert(kinds, kind)
		end
	end
	table.sort(kinds, function(a, b)
		local ia, ib = Config.PetIncome[a] or 0, Config.PetIncome[b] or 0
		if ia ~= ib then
			return ia < ib
		end
		return a < b
	end)
	local names = Config.BiomeNames and Config.BiomeNames[Config.World]
	table.insert(BIOMES, { name = names and names[i] or biome.Name, kinds = kinds })
end

local function ridden()
	local ok, list = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Caught") or "[]")
	local set = {}
	for _, kind in if ok and typeof(list) == "table" then list else {} do
		set[kind] = true
	end
	return set
end

local gui = Instance.new("ScreenGui")
gui.Name = "AnimalDex"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- under the HUD, so the button that closes it stays on top
gui.Enabled = false

local open = false
local pop = 1

-- A click anywhere off the panel closes it.
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
page.Active = true -- (clicks on it don't reach the backdrop)
local scale = Instance.new("UIScale")
scale.Parent = page
page.Parent = gui

local close = Instance.new("ImageButton")
close.Name = "Close"
close.BackgroundTransparency = 1
close.Image = CLOSE
close.AnchorPoint = Vector2.new(0.5, 0.5)
-- (centred on the panel's top right corner, as big on screen as the Worlds menu's: QM, Oct 15)
close.Position = UDim2.fromOffset(PAGE.X - 9, 49 + 9)
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
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = list

local pictures = {} -- [kind] = its ImageLabel
local rowWidth = PER_ROW * CELL + (PER_ROW - 1) * GAP
for b, biome in BIOMES do
	if #biome.kinds > 0 then
		local header = Instance.new("TextLabel")
		header.Name = "Biome" .. b
		header.LayoutOrder = b * 2 - 1
		header.BackgroundTransparency = 1
		header.FontFace = FREDOKA
		header.Text = biome.name
		header.TextColor3 = Color3.new(1, 1, 1)
		header.TextScaled = true
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Size = UDim2.fromOffset(rowWidth, HEADER)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 4
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = header
		header.Parent = list
		local rows = math.ceil(#biome.kinds / PER_ROW)
		local grid = Instance.new("Frame")
		grid.Name = "Animals" .. b
		grid.LayoutOrder = b * 2
		grid.BackgroundTransparency = 1
		grid.Size = UDim2.fromOffset(rowWidth, rows * CELL + (rows - 1) * GAP)
		local g = Instance.new("UIGridLayout")
		g.CellSize = UDim2.fromOffset(CELL, CELL)
		g.CellPadding = UDim2.fromOffset(GAP, GAP)
		g.SortOrder = Enum.SortOrder.LayoutOrder
		g.Parent = grid
		for k, kind in biome.kinds do
			local picture = Instance.new("ImageLabel")
			picture.Name = kind
			picture.LayoutOrder = k
			picture.BackgroundTransparency = 1
			picture.Image = PetFaces.HEADSHOTS[kind] or ""
			picture.ScaleType = Enum.ScaleType.Fit
			picture.Parent = grid
			pictures[kind] = picture
		end
		grid.Parent = list
	end
end

-- In colour once ridden, a black silhouette till then.
local function paint()
	local seen = ridden()
	for kind, picture in pictures do
		picture.ImageColor3 = if seen[kind] then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
	end
end
player:GetAttributeChangedSignal("Caught"):Connect(paint)
paint()

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

function AnimalDex.toggle(instant)
	open = not open
	if open then
		gui.Enabled = true
		paint()
		list.CanvasPosition = Vector2.zero
		ModalPop.open(setPop)
		Gamepad.openMenu("Pets", { close = AnimalDex.close })
	else
		Gamepad.closeMenu("Pets")
		ModalPop.close(setPop, function()
			gui.Enabled = false
		end, instant)
	end
	if AnimalDex.onToggle then
		AnimalDex.onToggle(open)
	end
end

function AnimalDex.isOpen()
	return open == true
end

function AnimalDex.close(instant)
	if open then
		AnimalDex.toggle(instant)
	end
end

close.Activated:Connect(function()
	AnimalDex.close()
end)
backdrop.Activated:Connect(function()
	AnimalDex.close()
end)

return AnimalDex
