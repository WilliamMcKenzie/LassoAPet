-- Nameplates over your own pets when you walk up to them (QM, Oct 7), centred:
-- the pet's rarity (QM, Oct 10: was its name) in its colour, the gold it earns a
-- second, and its speed (its Speed stat x 20, "m/s").
--
-- Only the NEAREST few of your pets within REACH get one, and only while you're on
-- foot. A pet with its plate up doesn't pop "+N$" (Ride.client skips the ones on
-- PenPets.plated); the rest of your pets keep popping.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local PenPets = require(script.Parent.PenPets)
local Outline = require(script.Parent.Outline)
local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer

local REACH = 16 -- studs from you to a pet's root where its plate shows
local LEAVE = 19 -- and where it goes again (a bit further, so it doesn't flicker at the edge)
local MOST = 4 -- plates at once, nearest first (a crowded pen would be a wall of them)
local HEIGHT = 3 -- studs: the name and speed lines' height (125 px in the reference)
local WIDTH = HEIGHT * 300 / 125
local TALL = HEIGHT * 1.45 -- studs: the plate's height with the gold line between them (QM, Oct 7)
local GOLD = if Config.Gems then Config.GemYellow else Color3.fromRGB(80, 255, 60) -- the gold line's bright green (gems' yellow in the Halloween world: Config.Gems, QM Oct 15)
local TIER_GROWTH = 1.2 -- the plate's size per size tier up from a small pet (QM, Oct 7)
local ABOVE = 0.6 -- studs between the pet's top and the plate
local FONT = Enum.Font.FredokaOne
local CHECK = 0.1 -- seconds between looks round
local RING_REACH = 5 -- studs from another player's pet's outline where it gets the ring (RIDE's reach on yours)

local COLORS = Config.RarityColors -- (QM, Oct 7)
local function colorOf(kind, fuse)
	return COLORS[Fusion.rarity(kind, fuse)] or COLORS.Common -- (a hybrid: the rarer of its two)
end

local function text(parent, size, position, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.AnchorPoint = Vector2.new(0.5, 0.5)
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
	board.Size = UDim2.fromScale(WIDTH * 2, TALL)
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
	-- Centred, top to bottom (QM, Oct 7): the name, the gold it earns a second (a
	-- little smaller, green) and its speed. Each may run the board's whole width: a
	-- name too long for that shrinks to fit.
	local name = text(plate, UDim2.fromScale(2, 0.41), UDim2.fromScale(0.5, 0.2), Color3.new(1, 1, 1))
	local gold = text(plate, UDim2.fromScale(2, 0.32), UDim2.fromScale(0.5, 0.555), GOLD)
	local speed = text(plate, UDim2.fromScale(2, 0.37), UDim2.fromScale(0.5, 0.83), Color3.new(1, 1, 1))
	-- In a folder of its own, adorned to the pet: inside the pet's model, the pet's
	-- ScaleTo would scale the plate with it (a medium pet's came out huge).
	local folder = workspace:FindFirstChild("PetPlates")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PetPlates"
		folder.Parent = workspace
	end
	board.Parent = folder
	local p = { board = board, scale = scale, name = name, gold = gold, speed = speed }
	plates[model] = p
	model.Destroying:Connect(function()
		board:Destroy()
		plates[model] = nil
		PenPets.plated[model] = nil
	end)
	return p
end

-- 15, 1.2k, 3.4m, ... (gold a second, short).
local function short(n)
	for _, unit in { { 1e9, "b" }, { 1e6, "m" }, { 1e3, "k" } } do
		if n >= unit[1] then
			return (string.format("%.1f", n / unit[1]):gsub("%.0$", "")) .. unit[2]
		end
	end
	return tostring(math.floor(n + 0.5))
end

local function show(model, kind, fuse, stats, income)
	local p = plates[model] or build(model)
	local s = Fusion.stats(kind, fuse, stats)
	local key = Fusion.key(kind, fuse) .. "/" .. s.Speed .. "/" .. income .. "/" .. Config.goldX(player)
	if p.key ~= key then
		p.key = key
		p.name.Text = (Fusion.rarity(kind, fuse)) -- its rarity, not its name (QM, Oct 10; a hybrid's: the rarer of its two)
		p.name.TextColor3 = colorOf(kind, fuse)
		p.gold.Text = if Config.Gems
			then short(income * Config.goldX(Players.LocalPlayer) * Config.Gems.Rate) .. " gems/s" -- (the Halloween world: they earn gems, Hatchery)
			else "$" .. short(income * Config.goldX(Players.LocalPlayer)) .. "/s" -- (x the x2 Gold pass and rebirths)
		p.speed.Text = math.floor(s.Speed * 20 + 0.5) .. "m/s"
	end
	local box, size = Outline.box(model)
	local grow = TIER_GROWTH ^ ((Config.PetTiers[kind] or 1) - 1)
	p.board.Size = UDim2.fromScale(WIDTH * 2 * grow, TALL * grow)
	p.board.Adornee = model.PrimaryPart
	p.board.StudsOffsetWorldSpace = Vector3.new(0, box.Y + size.Y / 2 + ABOVE + TALL * grow / 2, 0)
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
local otherRing, ringOn -- the ring round someone else's pet (Outline.ring), and which
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
	if root and humanoid and not humanoid.Sit and not humanoid.PlatformStand and not Hud.inLesson() -- (none in the fuse lesson)
		and not player:GetAttribute("EggPromptUp") -- (nor while an egg's prompt is up: Pen.client, QM)
		and not player:GetAttribute("MergeView") and not player:GetAttribute("Tutorial") then -- (nor in the merge view: FuseMenu, QM; nor the tutorial, QM Oct 11)
		local function consider(model, kind, fuse, stats, income)
			local pet = model.PrimaryPart
			if not kind or not pet or not model.Parent then
				return
			end
			local d = Vector2.new(pet.Position.X - root.Position.X, pet.Position.Z - root.Position.Z).Magnitude
			if d <= (if plates[model] and plates[model].on then LEAVE else REACH) then
				table.insert(candidates, { model = model, kind = kind, fuse = fuse, stats = stats, income = income, d = d })
			end
		end
		for model, info in PenPets.pets do
			-- (gold a second: a merged pet's for all it's made of, a hybrid's both pets': Hatchery's income)
			consider(model, info.kind, info.fuse, info.stats, info.income or (Config.PetIncome[info.kind] or 0) * (info.merged or 1))
		end
		-- Other players' pets show theirs too (QM, Oct 7), as yours do but for RIDE.
		for model, info in PenPets.others do
			consider(model, info.kind, info.fuse, info.stats, info.income or (Config.PetIncome[info.kind] or 0) * (info.merged or 1))
		end
		-- The pet on your spot (Ride.client's starter), unless it's the one you're out on.
		local starter = PenPets.starter
		if starter and starter.kind == player:GetAttribute("RidePet") then
			consider(starter.animal.model, starter.kind, starter.fuse, starter.stats,
				player:GetAttribute("RideIncome") or (Config.PetIncome[starter.kind] or 0) * (starter.merged or 1))
		end
		table.sort(candidates, function(a, b)
			return a.d < b.d
		end)
	end
	local keep = {}
	for i = 1, math.min(#candidates, MOST) do
		local c = candidates[i]
		keep[c.model] = true
		show(c.model, c.kind, c.fuse, c.stats, c.income)
	end
	for model in plates do
		if not keep[model] then
			hide(model)
		end
	end
	-- The ring round the nearest of someone else's pets once you're right by it, as
	-- RIDE's is round yours (Ride.client marks your own).
	local near
	for _, c in candidates do
		if PenPets.others[c.model] then
			local _, size = Outline.box(c.model)
			if c.d - math.max(size.X, size.Z) / 2 <= RING_REACH then
				near = c.model
			end
			break
		end
	end
	if near ~= ringOn then
		ringOn = near
		if near then
			otherRing = otherRing or Outline.ring(near)
			otherRing:fit(near, near.PrimaryPart)
		elseif otherRing then
			otherRing:hide()
		end
	end
end)
