-- Nameplates over your own pets when you walk up to them (QM, Oct 7): the pet's
-- name in its rarity's colour, and under it, a little right, its speed (its Speed
-- stat x 20, "m/s"), with QM's arm icon filling the spot to the left of both.
-- Laid out from QM's reference, measured in pixels: the whole plate is 300 x 125.
--
-- Only the NEAREST few of your pets within REACH get one, and only while you're on
-- foot. A pet with its plate up doesn't pop "+N$" (Ride.client skips the ones on
-- PenPets.plated); the rest of your pets keep popping.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Animals = ReplicatedStorage.Shared.Animals
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local PenPets = require(script.Parent.PenPets)
local Outline = require(script.Parent.Outline)

local player = Players.LocalPlayer

local REACH = 16 -- studs from you to a pet's root where its plate shows
local LEAVE = 19 -- and where it goes again (a bit further, so it doesn't flicker at the edge)
local MOST = 4 -- plates at once, nearest first (a crowded pen would be a wall of them)
local HEIGHT = 3 -- studs: the plate's height (125 px in the reference)
local WIDTH = HEIGHT * 300 / 125
local ABOVE = 0.6 -- studs between the pet's top and the plate
local ARM = "" -- rbxassetid of assets/ui/PowerArm.png, once Studio's uploaded it
local FONT = Enum.Font.FredokaOne
local CHECK = 0.1 -- seconds between looks round

-- The rarity colours of the inventory slots (Inventory.luau's RARITY).
local COLORS = {
	Common = Color3.fromRGB(150, 160, 175),
	Uncommon = Color3.fromRGB(70, 170, 60),
	Rare = Color3.fromRGB(50, 120, 220),
	Epic = Color3.fromRGB(150, 60, 200),
	Legendary = Color3.fromRGB(230, 170, 30),
}
local RANKS = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }

local function rarityOf(kind)
	local module = kind and Animals:FindFirstChild(kind)
	local ok, class = pcall(require, module)
	return ok and class and class.Rarity or "Common"
end

-- A hybrid's colour is the rarer of its two pets'.
local function colorOf(kind, fuse)
	local rarity = rarityOf(kind)
	if fuse and (RANKS[rarityOf(fuse)] or 0) > (RANKS[rarity] or 0) then
		rarity = rarityOf(fuse)
	end
	return COLORS[rarity] or COLORS.Common
end

local function text(parent, size, position, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Size = size
	label.Position = position
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	label.Parent = parent
	return label
end

local plates = {} -- [model] = { board, scale, name, speed, key, on }

local function build(model)
	local board = Instance.new("BillboardGui")
	board.Name = "PetPlate"
	-- Twice as wide as the plate, which sits in its middle, so a long name can run
	-- on to the right without being cut off.
	board.Size = UDim2.fromScale(WIDTH * 2, HEIGHT)
	board.LightInfluence = 0
	board.AlwaysOnTop = true
	board.ResetOnSpawn = false
	board.Enabled = false
	local plate = Instance.new("Frame")
	plate.BackgroundTransparency = 1
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = UDim2.fromScale(0.5, 0.5)
	plate.Size = UDim2.fromScale(0.5, 1)
	plate.Parent = board
	local scale = Instance.new("UIScale")
	scale.Parent = plate
	-- The arm: from the plate's left edge, level with the middle of the name down
	-- to the bottom of the speed (91 x 91 px at (0, 30)).
	local arm = Instance.new("ImageLabel")
	arm.BackgroundTransparency = 1
	arm.Image = ARM
	arm.ScaleType = Enum.ScaleType.Fit
	arm.Position = UDim2.fromScale(0, 30 / 125)
	arm.Size = UDim2.fromScale(91 / 300, 91 / 125)
	arm.Parent = plate
	-- The name's letters span 0-57 px down from x 90; the speed's 71-125 from x 106,
	-- just right of the name's start. (A label's letters are ~3/4 its height.)
	-- Both run to the board's right edge: a name too long for that shrinks to fit.
	local name = text(plate, UDim2.fromScale(1.5 - 90 / 300, 0.6), UDim2.fromScale(90 / 300, 28 / 125), Color3.new(1, 1, 1))
	local speed = text(plate, UDim2.fromScale(1.5 - 106 / 300, 0.58), UDim2.fromScale(106 / 300, 98 / 125), Color3.new(1, 1, 1))
	board.Parent = player:WaitForChild("PlayerGui")
	local p = { board = board, scale = scale, name = name, speed = speed }
	plates[model] = p
	model.Destroying:Connect(function()
		board:Destroy()
		plates[model] = nil
		PenPets.plated[model] = nil
	end)
	return p
end

local function show(model, kind, fuse, stats)
	local p = plates[model] or build(model)
	local s = Fusion.stats(kind, fuse, stats)
	local key = Fusion.key(kind, fuse) .. "/" .. s.Speed
	if p.key ~= key then
		p.key = key
		p.name.Text = Fusion.name(kind) -- a hybrid goes by its base animal's name: no fused names (QM)
		p.name.TextColor3 = colorOf(kind, fuse)
		p.speed.Text = math.floor(s.Speed * 20 + 0.5) .. "m/s"
	end
	local box, size = Outline.box(model)
	p.board.Adornee = model.PrimaryPart
	p.board.StudsOffsetWorldSpace = Vector3.new(0, box.Y + size.Y / 2 + ABOVE + HEIGHT / 2, 0)
	if not p.on then
		p.on = true
		p.board.Enabled = true
		p.scale.Scale = 0.3
		TweenService:Create(p.scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	PenPets.plated[model] = true
end

local function hide(model)
	local p = plates[model]
	if p and p.on then
		p.on = false
		p.board.Enabled = false
	end
	PenPets.plated[model] = nil
end

local candidates = {}
local untilCheck = 0
RunService.Heartbeat:Connect(function(dt)
	untilCheck -= dt
	if untilCheck > 0 then
		return
	end
	untilCheck = CHECK
	table.clear(candidates)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	-- (Sitting is riding; PlatformStand is lying flat after a crash.)
	if root and humanoid and not humanoid.Sit and not humanoid.PlatformStand then
		local function consider(model, kind, fuse, stats)
			local pet = model.PrimaryPart
			if not kind or not pet or not model.Parent then
				return
			end
			local d = Vector2.new(pet.Position.X - root.Position.X, pet.Position.Z - root.Position.Z).Magnitude
			if d <= (if plates[model] and plates[model].on then LEAVE else REACH) then
				table.insert(candidates, { model = model, kind = kind, fuse = fuse, stats = stats, d = d })
			end
		end
		for model, info in PenPets.pets do
			consider(model, info.kind, info.fuse, info.stats)
		end
		-- The pet on your spot (Ride.client's starter), unless it's the one you're out on.
		local starter = PenPets.starter
		if starter and starter.kind == player:GetAttribute("RidePet") then
			consider(starter.animal.model, starter.kind, starter.fuse, starter.stats)
		end
		table.sort(candidates, function(a, b)
			return a.d < b.d
		end)
	end
	local keep = {}
	for i = 1, math.min(#candidates, MOST) do
		local c = candidates[i]
		keep[c.model] = true
		show(c.model, c.kind, c.fuse, c.stats)
	end
	for model in plates do
		if not keep[model] then
			hide(model)
		end
	end
end)
