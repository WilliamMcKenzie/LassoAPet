-- The Index in the native UI (Config.NativeUi, QM Nov 6): Fight to Steal an Egg's Index popup
-- (its client/IndexPanel, 1:1 in look): the pink and purple header with "Index" and the red
-- X over the dark studded panel. In it:
--   left    a box scrolling through a section per biome of this world: the biome's card (its
--           grass colour, its name) and its animals as tiles in a collage, then a bar of how
--           many of them you've had. One you've never had (the "Caught" attribute,
--           Hatchery) is a dark silhouette. Each tile's label is its spawn odds in its biome,
--           "1 in N" (its Herd weight over the herd's total, at luck 1: QM, Nov 7). Every
--           animal that runs in a biome is in (the alphas and the new ones too); one with no
--           uploaded headshot shows its model in 3D (PetStill).
--   bottom  Unlocked: had / every animal, by the Index book
--   right   the picked animal's card (its rarity's colours: name, rarity, cash a second;
--           "???" for one not had), and under it its reward (Config.indexReward's cash) with
--           Claim! (Locked till you've had it; Hatchery's IndexClaim). Once that's claimed
--           the box shows where it runs and its speed instead, as the reference's stats.
-- A red "!" sits on the Index button while there's a reward to claim (NativeIndex.badge).
-- Client/AnimalDex hands its toggle, close and isOpen to this while the native UI's on.
--
-- The collage (as the reference's): a biome's grid is COLS cells across and 2 down (more
-- rows when it has more), tiled by exactly its number of animals with 2x2, 1x2, 2x1 and 1x1
-- tiles, as many big ones as fit; its rarest get the biggest tiles.
--
--   NativeIndex.toggle() / NativeIndex.close() / NativeIndex.isOpen()
--   NativeIndex.badge(indexButton)   -- once, from BaseUi

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HudImages = require(script.Parent.HudImages)
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local PetFaces = require(script.Parent.PetFaces)
local PetStill = require(script.Parent.PetStill)
local RarityLook = require(script.Parent.RarityLook)
local Ui = require(script.Parent.Ui)
local UiFx = require(script.Parent.UiFx)

local NativeIndex = {}

local player = Players.LocalPlayer
local fig, label, art, button = HudKit.fig, HudKit.label, HudKit.art, HudKit.button

-- (QM's Figma px, through fig: the popup is the reference's 2268 x 1370)
local W, H = 2268, 1370
local LEFT_W = 1600 -- the sections' box
local BOX_TOP, BOX_H = 323, 800
local RIGHT_X = 1680
local RIGHT_W = W - 40 - RIGHT_X
local CARD_H = 560 -- the picked animal's card
local PAD = 22
local PICTURE_W = 400
local COLS = 5
local GAP = 14
local BAR_H = 100
local CASH_GREEN = Color3.fromRGB(0, 255, 0)
local LOCKED_SHADE = 0.45 -- the dark over a tile not had (its transparency)
local SILHOUETTE = 0.35 -- an animal not had: black, this transparent
local PICK = 8 -- the picked tile's white ring
local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Exclusive" }

local gui, sections, card, details, unlocked, badge
local tiles = {} -- [kind] = tile
local bars = {} -- [biome number] = { section, kinds }
local picked

-- an animal's name, rarity and biome
local info = {}
local function about(kind)
	if not info[kind] then
		local module = ReplicatedStorage.Shared.Animals:FindFirstChild(kind)
		local ok, class = pcall(require, module)
		local name = ok and typeof(class) == "table" and class.Name
		local rarity = ok and typeof(class) == "table" and class.Rarity
		info[kind] = {
			name = if type(name) == "string" then name else (kind:gsub("(%l)(%u)", "%1 %2")),
			rarity = if table.find(RARITIES, rarity) then rarity else "Common",
		}
	end
	return info[kind]
end

-- This world's biomes, each with its animals (the herd's, cheapest first), as the old Index
local BIOMES = {}
local oddsOf = {} -- [kind] = N, its spawn odds "1 in N" in its (first) biome
for i, biome in Config.allBiomes() do -- (and the endless course's, past the Ocean: Config.Endless)
	local kinds = {}
	local total = 0
	for kind, weight in biome.Herd or {} do
		if weight > 0 and ReplicatedStorage.Shared.Animals:FindFirstChild(kind) then
			table.insert(kinds, kind)
		end
		total += math.max(weight, 0)
	end
	for _, kind in kinds do -- 1 in this many of the biome's spawns
		oddsOf[kind] = oddsOf[kind] or total / biome.Herd[kind]
	end
	table.sort(kinds, function(a, b)
		local ia, ib = Config.PetIncome[a] or 0, Config.PetIncome[b] or 0
		if ia ~= ib then
			return ia < ib
		end
		return a < b
	end)
	local names = Config.BiomeNames and Config.BiomeNames[Config.World]
	local colours = biome.GroundColors
	table.insert(BIOMES, {
		name = names and names[i] or biome.DisplayName or biome.Name,
		kinds = kinds,
		tint = colours and colours[#colours] or Color3.fromRGB(80, 80, 80),
		picture = biome.Picture, -- (its render: design/biomes, QM Nov 7)
	})
end
local biomeOf = {}
for i, biome in BIOMES do
	for _, kind in biome.kinds do
		biomeOf[kind] = biomeOf[kind] or i
	end
end

local function had(attr)
	local ok, list = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute(attr or "Caught") or "[]")
	local set = {}
	for _, kind in if ok and typeof(list) == "table" then list else {} do
		set[kind] = true
	end
	return set
end

-- "1 in 37", "1 in 2.5", "1 in 12,500"
local function oddsText(kind)
	local n = oddsOf[kind]
	if not n then
		return "???"
	end
	local text
	if n < 10 then
		text = (string.format("%.1f", n):gsub("%.0$", ""))
	else
		text = tostring(math.round(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	end
	return "1 in " .. text
end

-- an animal's picture in a holder (its "Picture" ImageLabel): its headshot, or its model in
-- 3D (PetStill) as "View" when it has none uploaded
local function setPicture(picture, kind)
	local old = picture.Parent and picture.Parent:FindFirstChild("View")
	if old and old:GetAttribute("Kind") ~= kind then
		old:Destroy()
		old = nil
	end
	local headshot = PetFaces.HEADSHOTS[kind]
	picture.Image = headshot or ""
	if (headshot == nil or headshot == "") and not old and picture.Parent then
		local view = PetStill.view(kind)
		if view then
			view.Name = "View"
			view:SetAttribute("Kind", kind)
			view.AnchorPoint = picture.AnchorPoint
			view.Position = picture.Position
			view.Size = picture.Size
			view.ZIndex = picture.ZIndex
			view.Parent = picture.Parent
		end
	end
end

-- had: full colour; not: a dark silhouette (the headshot's or the 3D view's)
local function shadePicture(picture, found)
	local colour = if found then Color3.new(1, 1, 1) else HudKit.BLACK
	local transparency = if found then 0 else SILHOUETTE
	picture.ImageColor3, picture.ImageTransparency = colour, transparency
	local view = picture.Parent and picture.Parent:FindFirstChild("View")
	if view then
		view.ImageColor3, view.ImageTransparency = colour, transparency
		view.Ambient = if found then Color3.fromRGB(200, 200, 200) else HudKit.BLACK
		view.LightColor = if found then Color3.new(1, 1, 1) else HudKit.BLACK
	end
end

-- ---- the collage ------------------------------------------------------------------------

local SHAPES = { { 2, 2 }, { 1, 2 }, { 2, 1 }, { 1, 1 } } -- (tried biggest first)

-- n tiles exactly filling a COLS-wide grid: { { x, y, w, h } } (cells, from 0) and its rows
local function collage(n)
	local rows = math.max(2, math.ceil(n / COLS))
	while true do
		local cells = COLS * rows
		local taken, placed = {}, {}
		local best, bestScore
		local function score()
			local s = 0
			for _, p in placed do
				if p[3] == 2 and p[4] == 2 then
					s += 3
				elseif p[3] ~= p[4] then
					s -= 1
				end
			end
			return s
		end
		local function solve(free)
			local first
			for i = 0, cells - 1 do
				if not taken[i] then
					first = i
					break
				end
			end
			if not first then
				if #placed == n then
					local s = score()
					if not bestScore or s > bestScore then
						bestScore, best = s, table.clone(placed)
					end
				end
				return
			end
			local left = n - #placed
			if left <= 0 or free < left or free > 4 * left then
				return
			end
			local x, y = first % COLS, first // COLS
			for _, shape in SHAPES do
				local w, h = shape[1], shape[2]
				if x + w <= COLS and y + h <= rows then
					local fits = true
					for dy = 0, h - 1 do
						for dx = 0, w - 1 do
							if taken[(y + dy) * COLS + x + dx] then
								fits = false
							end
						end
					end
					if fits then
						for dy = 0, h - 1 do
							for dx = 0, w - 1 do
								taken[(y + dy) * COLS + x + dx] = true
							end
						end
						table.insert(placed, { x, y, w, h })
						solve(free - w * h)
						table.remove(placed)
						for dy = 0, h - 1 do
							for dx = 0, w - 1 do
								taken[(y + dy) * COLS + x + dx] = nil
							end
						end
					end
				end
			end
		end
		if n > 0 and n <= cells then
			solve(cells)
		end
		if best or n == 0 then
			return best or {}, rows
		end
		rows += 1
	end
end

-- ---- building ---------------------------------------------------------------------------

-- a rarity's colours on a back's Fill
local function paintBack(back, rarity)
	local fill = back and back:FindFirstChild("Fill")
	if not fill then
		return
	end
	local look = Config.NativeUi.Rarities[rarity] or Config.NativeUi.Rarities.Common
	fill.Rotation = 90
	if look.top then
		fill.Color = if look.at < 1
			then ColorSequence.new({
				ColorSequenceKeypoint.new(0, look.top),
				ColorSequenceKeypoint.new(1 - look.at, look.top),
				ColorSequenceKeypoint.new(1, look.bottom),
			})
			else ColorSequence.new(look.top, look.bottom)
	else
		fill.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170))
	end
end

local function makeTile()
	local tile = Instance.new("ImageButton")
	tile.BackgroundTransparency = 1
	tile.Image = ""
	tile.AutoButtonColor = false
	HudKit.back(tile, "Card", {})
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, fig(10))
	round.Parent = tile
	local grow = Instance.new("UIScale")
	grow.Name = "Hover"
	grow.Parent = tile
	local shade = Instance.new("Frame")
	shade.Name = "Shade"
	shade.BackgroundColor3 = HudKit.BLACK
	shade.BackgroundTransparency = LOCKED_SHADE
	shade.BorderSizePixel = 0
	shade.Size = UDim2.fromScale(1, 1)
	shade.ZIndex = 2
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, fig(10))
	corner.Parent = shade
	shade.Parent = tile
	local picture = Instance.new("ImageLabel")
	picture.Name = "Picture"
	picture.BackgroundTransparency = 1
	picture.ScaleType = Enum.ScaleType.Fit
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, 0.55)
	picture.Size = UDim2.fromScale(0.86, 0.8)
	picture.ZIndex = 3
	picture.Parent = tile
	local name = label(tile, "PetName", {
		Text = "???",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, fig(6)),
		Size = UDim2.new(0.92, 0, 0, fig(40)),
		ZIndex = 4,
	})
	name.Outline.Thickness = 2
	local ring = Instance.new("UIStroke")
	ring.Name = "Pick"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = Color3.new(1, 1, 1)
	ring.Thickness = fig(PICK)
	ring.Enabled = false
	ring.Parent = tile
	return tile
end

local function showCard(kind)
	local a = about(kind)
	local found = had()[kind] == true
	paintBack(card, a.rarity)
	local picture = card.PictureBox.Picture
	setPicture(picture, kind)
	shadePicture(picture, found)
	card.PetName.Text = if found then a.name else "???"
	RarityLook.paint(card.Rarity, a.rarity, card.Rarity:FindFirstChild("Outline"))
	card.PetCash.Text = if found then "$" .. Config.short(Config.PetIncome[kind] or 0) .. "/s" else "???"
	local biome = BIOMES[biomeOf[kind]]
	details.Where.Value.Text = biome and biome.name or "???"
	details.Where.Icon.Image = biome and biome.picture or ""
	local stats = Config.AnimalStats and Config.AnimalStats[kind]
	details.Speed.Value.Text = if found and stats and stats.Speed then string.format("%.2g Speed", stats.Speed) else "??? Speed"
	-- its reward and Claim! (Locked till you've had it), or once claimed where it runs and its speed
	local done = found and had("IndexClaimed")[kind] == true
	local claim = details.Claim
	claim.Visible = not done
	details.Where.Visible, details.Speed.Visible = done, done
	claim.CashReward.Amount.Text = "$" .. Config.short(Config.indexReward(kind)):upper()
	claim.ClaimButton.Visible = found
	claim.LockedButton.Visible = not found
end

local function pick(kind)
	if picked and tiles[picked] then
		tiles[picked].Pick.Enabled = false
	end
	picked = kind
	if tiles[kind] then
		tiles[kind].Pick.Enabled = true
	end
	showCard(kind)
end

local function makeSection(i)
	local biome = BIOMES[i]
	local section = Instance.new("Frame")
	section.Name = "Section" .. i
	section.BackgroundTransparency = 1
	section.LayoutOrder = i
	local picture = HudKit.back(section, "IndexCard", {
		Name = "Biome",
		Position = UDim2.fromOffset(fig(PAD), fig(PAD)),
		Size = UDim2.new(0, fig(PICTURE_W), 1, -2 * fig(PAD)),
		ClipsDescendants = true,
	})
	local fill = picture:FindFirstChild("Fill")
	if fill then
		fill.Color = ColorSequence.new(biome.tint:Lerp(Color3.new(1, 1, 1), 0.25), biome.tint:Lerp(HudKit.BLACK, 0.35))
		fill.Rotation = 90
	end
	if biome.picture then -- the biome's render over its colours, cropped to the card (QM, Nov 7: "sidebar fix")
		local render = Instance.new("ImageLabel")
		render.Name = "Render"
		render.BackgroundTransparency = 1
		render.Image = biome.picture
		render.ScaleType = Enum.ScaleType.Crop
		render.Size = UDim2.fromScale(1, 1)
		render.ZIndex = 2
		local corner = picture:FindFirstChildOfClass("UICorner")
		if corner then
			corner:Clone().Parent = render
		end
		render.Parent = picture
	end
	label(picture, "BiomeName", {
		Text = biome.name,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, fig(80)),
		ZIndex = 3,
	})
	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromOffset(fig(PAD + PICTURE_W + PAD), fig(PAD))
	grid.Size = UDim2.new(1, -fig(PAD + PICTURE_W + 2 * PAD), 1, -fig(2 * PAD + BAR_H + PAD))
	grid.Parent = section
	-- the bar: dark track, green fill, "4/7", the biome's rarest egg at its end
	local track = HudKit.back(section, "EggTrack", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, fig(PAD + PICTURE_W + PAD), 1, -fig(PAD)),
		Size = UDim2.new(1, -fig(PAD + PICTURE_W + 2 * PAD + 60), 0, fig(BAR_H)),
	})
	local found = Instance.new("Frame")
	found.Name = "Found"
	found.BackgroundTransparency = 1
	found.ClipsDescendants = true
	found.Size = UDim2.fromScale(0, 1)
	found.ZIndex = 2
	found.Parent = track
	HudKit.back(found, "EggGrow", { Name = "Green", ZIndex = 2 })
	label(track, "Count", {
		Text = "0/0",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(75),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
	})
	local egg = Instance.new("ImageLabel")
	egg.Name = "Egg"
	egg.BackgroundTransparency = 1
	egg.ScaleType = Enum.ScaleType.Fit
	egg.AnchorPoint = Vector2.new(0.5, 0.5)
	egg.Position = UDim2.new(1, fig(10), 0.5, 0)
	egg.Size = UDim2.fromOffset(fig(150), fig(150))
	egg.Rotation = 15
	egg.ZIndex = 4
	egg.Image = (Config.EggIcons or {})[biome.kinds[#biome.kinds]] or ""
	egg.Parent = track

	-- the collage: the biggest tiles to the rarest (kinds are cheapest first)
	local kinds = biome.kinds
	local layout, rows = collage(#kinds)
	local byArea = {}
	for k = 1, #layout do
		byArea[k] = k
	end
	table.sort(byArea, function(a, b)
		local la, lb = layout[a], layout[b]
		local area = la[3] * la[4] - lb[3] * lb[4]
		if area ~= 0 then
			return area > 0
		end
		return a < b
	end)
	local gridW = fig(LEFT_W) - 2 * fig(8) - 6 - fig(PAD + PICTURE_W + 2 * PAD) -- (6: the scroll bar)
	local cell = (gridW - (COLS - 1) * fig(GAP)) / COLS
	local gridH = rows * cell + (rows - 1) * fig(GAP)
	section.Size = UDim2.new(1, 0, 0, math.round(gridH + fig(2 * PAD + BAR_H + PAD)))
	for rank, at in byArea do
		local kind = kinds[#kinds - rank + 1]
		local p = layout[at]
		local tile = makeTile()
		tile.Name = kind
		tile.Position = UDim2.fromOffset(math.round(p[1] * (cell + fig(GAP))), math.round(p[2] * (cell + fig(GAP))))
		tile.Size = UDim2.fromOffset(math.round(p[3] * cell + (p[3] - 1) * fig(GAP)), math.round(p[4] * cell + (p[4] - 1) * fig(GAP)))
		paintBack(tile:FindFirstChild("Back"), about(kind).rarity)
		tile.Parent = grid
		setPicture(tile.Picture, kind)
		tile.PetName.Text = oddsText(kind)
		if p[3] == 2 and p[4] == 2 then
			tile.PetName.Size = UDim2.new(0.92, 0, 0, fig(60))
		end
		HudKit.hover(tile)
		tile.Activated:Connect(function()
			pick(kind)
		end)
		tiles[kind] = tile
	end
	section.Parent = sections
	bars[i] = section
end

local function build()
	local root = NativeHud.popupRoot()
	local close
	gui, close = HudKit.popup(root, "IndexPanel", "Index", "PinkHeader")
	UiFx.menu(gui)
	close.Activated:Connect(function()
		UiFx.popOut(gui)
	end)
	gui:GetPropertyChangedSignal("Visible"):Connect(function()
		NativeHud.haze("Index", gui.Visible)
	end)

	-- the sections' box
	local box = HudKit.back(gui, "IndexBox", {
		Name = "Box",
		Position = UDim2.fromOffset(fig(40), fig(BOX_TOP)),
		Size = UDim2.fromOffset(fig(LEFT_W), fig(BOX_H)),
		ZIndex = 2,
	})
	sections = Ui.make(box, "Sections", "ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(fig(8), fig(8)),
		Size = UDim2.new(1, -fig(16), 1, -fig(16)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
		ZIndex = 2,
	})
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, fig(10))
	layout.Parent = sections

	-- Unlocked: X/Y, the book over its left end
	unlocked = HudKit.back(gui, "IndexBox", {
		Name = "Unlocked",
		Position = UDim2.fromOffset(fig(40 + 110), fig(BOX_TOP + BOX_H + 40)),
		Size = UDim2.fromOffset(fig(LEFT_W - 110), fig(H - 40 - (BOX_TOP + BOX_H + 40))),
		ZIndex = 2,
	})
	label(unlocked, "Count", {
		Text = "Unlocked: 0/0",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(95),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
	})
	local book = Ui.make(gui, "BookIcon", "ImageLabel", {
		BackgroundTransparency = 1,
		Image = HudImages.IndexIcon or "",
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(40 + 110), fig(BOX_TOP + BOX_H + 40 + 80)),
		Size = UDim2.fromOffset(fig(220), fig(220)),
		Rotation = -8,
		ZIndex = 5,
	})
	HudKit.outlineArt(book, 3)

	-- the picked animal's card
	card = HudKit.back(gui, "Card", {
		Name = "PetCard",
		Position = UDim2.fromOffset(fig(RIGHT_X), fig(BOX_TOP)),
		Size = UDim2.fromOffset(fig(RIGHT_W), fig(CARD_H)),
		ZIndex = 2,
	})
	local frame = HudKit.back(card, "Dark", {
		Name = "PictureBox",
		Position = UDim2.fromOffset(fig(60), fig(40)),
		Size = UDim2.new(1, -fig(120), 0, fig(260)),
		ZIndex = 3,
	})
	Ui.make(frame, "Picture", "ImageLabel", {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromScale(0.05, 0.05),
		Size = UDim2.fromScale(0.9, 0.9),
		ZIndex = 4,
	})
	for i, l in {
		{ "PetName", "???", Color3.new(1, 1, 1) },
		{ "Rarity", "Common", Color3.new(1, 1, 1) },
		{ "PetCash", "???", CASH_GREEN },
	} do
		local t = label(card, l[1], {
			Text = l[2],
			TextColor3 = l[3],
			TextXAlignment = Enum.TextXAlignment.Center,
			TextScaled = true,
			Position = UDim2.fromOffset(fig(20), fig(310 + (i - 1) * 76)),
			Size = UDim2.new(1, -fig(40), 0, fig(76)),
			ZIndex = 4,
		})
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = fig(85)
		limit.Parent = t
	end

	-- under it: where it runs and its speed (the reference's stats box)
	details = HudKit.back(gui, "IndexCard", {
		Name = "Details",
		Position = UDim2.fromOffset(fig(RIGHT_X), fig(BOX_TOP + CARD_H + 40)),
		Size = UDim2.fromOffset(fig(RIGHT_W), fig(H - 40 - (BOX_TOP + CARD_H + 40))),
		ZIndex = 2,
	})
	local claim = Ui.make(details, "Claim", "Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3 })
	label(claim, "Heading", {
		Text = "Rewards:",
		TextSize = fig(48),
		Position = UDim2.fromOffset(fig(30), fig(14)),
		Size = UDim2.fromOffset(fig(300), fig(56)),
		ZIndex = 4,
	})
	local slot = HudKit.back(claim, "Dark", {
		Name = "CashReward",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, fig(68)),
		Size = UDim2.fromOffset(fig(160), fig(160)),
		ZIndex = 4,
	})
	-- (QM, Nov 7: Fight to Steal an Egg's high-res cash stack, its Shop and Offline Cash one,
	-- black outline drawn in; not the 34 px gain icon)
	local cashIcon = art(slot, "Icon", {
		Image = HudImages.CashStack or "",
		Position = UDim2.fromScale(0.1, 0.02),
		Size = UDim2.fromScale(0.8, 0.8),
		ZIndex = 5,
	})
	cashIcon.Image = HudImages.CashStack or ""
	label(slot, "Amount", {
		Text = "$1K",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -fig(6)),
		Size = UDim2.new(0.95, 0, 0, fig(52)),
		ZIndex = 6,
	})
	for _, b in { { "ClaimButton", "Claim!", "GreenPlain" }, { "LockedButton", "Locked", "GreyPlain" } } do
		local btn = button(claim, b[1], RIGHT_W - 120, 110, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -fig(20)),
			ZIndex = 4,
		}, b[3])
		label(btn, "Text", {
			Text = b[2],
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(75),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
		})
	end
	local claimButton = claim.ClaimButton
	claimButton.Activated:Connect(function()
		local remote = ReplicatedStorage:FindFirstChild("IndexClaim")
		if remote and picked and not claimButton:GetAttribute("Busy") then
			claimButton:SetAttribute("Busy", true)
			local ok, done = pcall(remote.InvokeServer, remote, picked)
			if ok and done then
				UiFx.play("Claim")
			else
				UiFx.shake(claimButton)
			end
			claimButton:SetAttribute("Busy", nil)
		end
	end)
	-- once claimed: Fight to Steal an Egg's stat rows (its IndexPanel), a 96 px icon and a big
	-- outlined label each; Where wears the biome's render as its icon (FTSAE has no such row)
	for i, s in { { "Where", "", "Meadow" }, { "Speed", HudImages.SpeedIcon or "", "??? Speed" } } do
		local row = Ui.make(details, s[1], "Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(fig(40), fig(22 + (i - 1) * 100)),
			Size = UDim2.new(1, -fig(80), 0, fig(96)),
			ZIndex = 4,
		})
		local icon = art(row, "Icon", {
			Image = s[2],
			Size = UDim2.fromOffset(fig(96), fig(96)),
			ZIndex = 5,
		})
		if s[1] == "Where" then
			icon.ScaleType = Enum.ScaleType.Crop
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, fig(16))
			corner.Parent = icon
			local edge = Instance.new("UIStroke")
			edge.Color = HudKit.BLACK
			edge.Thickness = HudKit.TEXT_OUTLINE
			edge.Parent = icon
		end
		label(row, "Value", {
			Text = s[3],
			TextSize = fig(70),
			Position = UDim2.fromOffset(fig(120), 0),
			Size = UDim2.new(1, -fig(120), 1, 0),
			ZIndex = 5,
		})
	end

	for i in BIOMES do
		makeSection(i)
	end
end

local function refresh()
	local seen = had()
	local total, have = 0, 0
	for i, biome in BIOMES do
		local n = 0
		for _, kind in biome.kinds do
			local tile = tiles[kind]
			local f = seen[kind] == true
			if f then
				n += 1
			end
			if tile then
				tile.Shade.Visible = not f
				shadePicture(tile.Picture, f)
			end
		end
		total += #biome.kinds
		have += n
		local section = bars[i]
		if section then
			section.Bar.Count.Text = n .. "/" .. #biome.kinds
			section.Bar.Found.Size = UDim2.fromScale(if #biome.kinds > 0 then n / #biome.kinds else 0, 1)
		end
	end
	unlocked.Count.Text = "Unlocked: " .. have .. "/" .. total
	NativeIndex.updateBadge()
	if not picked then
		local first = BIOMES[1] and BIOMES[1].kinds[1]
		if first then
			pick(first)
		end
	else
		showCard(picked)
	end
end

-- the red "!" on the Index button while something you've had has its reward to claim
function NativeIndex.updateBadge()
	if not badge then
		return
	end
	local claimed = had("IndexClaimed")
	local claimable = false
	for kind in had() do
		if biomeOf[kind] and not claimed[kind] then
			claimable = true
			break
		end
	end
	badge.Visible = claimable
end

function NativeIndex.badge(indexButton)
	badge = Instance.new("Frame")
	badge.Name = "IndexBadge"
	badge.BackgroundColor3 = Color3.fromHex("ff0000")
	badge.Position = UDim2.new(1, -fig(36), 0, -fig(26))
	badge.Size = UDim2.fromOffset(fig(64), fig(64))
	badge.ZIndex = 10
	badge.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = badge
	local border = Instance.new("UIStroke")
	border.Name = "Border"
	border.Color = Color3.fromHex("770000")
	border.Thickness = fig(5)
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = badge
	local mark = label(badge, "Mark", {
		Text = "!",
		TextSize = fig(55),
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 11,
	})
	mark.Outline.Color = Color3.fromHex("770000")
	mark.Outline.Thickness = fig(3)
	badge.Parent = indexButton
	for _, attr in { "Caught", "IndexClaimed" } do
		player:GetAttributeChangedSignal(attr):Connect(NativeIndex.updateBadge)
	end
	NativeIndex.updateBadge()
end

function NativeIndex.isOpen()
	return gui ~= nil and UiFx.isOpen(gui)
end

function NativeIndex.toggle()
	if not gui then
		build()
		for _, attr in { "Caught", "IndexClaimed" } do
			player:GetAttributeChangedSignal(attr):Connect(function()
				if gui.Visible then
					refresh()
				end
			end)
		end
	end
	if not UiFx.isOpen(gui) then
		refresh()
		sections.CanvasPosition = Vector2.zero
	end
	UiFx.toggle(gui)
end

function NativeIndex.close()
	if gui then
		UiFx.popOut(gui)
	end
end

return NativeIndex
