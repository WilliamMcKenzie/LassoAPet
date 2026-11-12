-- The animal lineup (QM, Oct 11): every animal, side on, standing in rows by biome on a
-- grey floor high over the base, its name over it, so their sizes can be compared and
-- set. Run in Studio's Edit mode (the command bar, or Claude's c.sh Edit).
--
-- Resize one: select its model in workspace.AnimalLineup and set Scale (Properties >
-- Transform), or use the Scale tool. Then tools/lineup_read.luau reads back what
-- changed, for Config.AnimalScale.
--
-- Not saved with the place: everything here is Archivable = false, so it can't be
-- published by accident, and it's gone when Studio closes. MODE "remove" takes it away.

local MODE = "build"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- (built from a fresh copy of Shared, so the modules load as they are now: a module the
-- command bar already required stays cached, and one stuck waiting stays stuck)
local Shared = ReplicatedStorage.Shared:Clone()
Shared.Name = "LineupShared"
Shared.Parent = game:GetService("ServerStorage")
local Config = require(Shared.Config)
local Animals = Shared.Animals

local HEIGHT = 400 -- studs up, over the base
local ROW_GAP = 50
local GAP = 8

local old = workspace:FindFirstChild("AnimalLineup")
if old then
	old:Destroy()
end
if MODE == "remove" then
	Shared:Destroy()
	return "removed"
end

local lineup = Instance.new("Folder")
lineup.Name = "AnimalLineup"
lineup.Archivable = false

-- Rows: each biome's herd, rarest last, then everything else.
local RARITY = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
local rows, placed = {}, {}
local function rarity(kind)
	local ok, class = pcall(require, Animals[kind])
	return ok and RARITY[class.Rarity] or 0
end
for _, biome in Config.Biomes do
	local row = { name = biome.Name, kinds = {} }
	for kind in biome.Herd do
		if Animals:FindFirstChild(kind) and not placed[kind] then
			placed[kind] = true
			table.insert(row.kinds, kind)
		end
	end
	table.sort(row.kinds, function(a, b)
		return rarity(a) < rarity(b) or (rarity(a) == rarity(b) and a < b)
	end)
	table.insert(rows, row)
end
local rest = { name = "Other", kinds = {} }
for _, m in Animals:GetChildren() do
	if m:IsA("ModuleScript") and not m.Name:find("Model$") and m.Name ~= "Rig" and not placed[m.Name] then
		table.insert(rest.kinds, m.Name)
	end
end
table.sort(rest.kinds)
table.insert(rows, rest)

local function label(adornee, text, size)
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(220, 40)
	board.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 3, 0)
	board.AlwaysOnTop = true
	board.Adornee = adornee
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Text = text
	t.Parent = board
	return board
end

local widest = 0
local count = 0
for r, row in rows do
	local z = -(r - 1) * ROW_GAP
	local x = 0
	for _, kind in row.kinds do
		local ok, animal = pcall(function()
			return require(Animals[kind]).new()
		end)
		if ok and animal then
			local model = animal.model
			model.Name = kind
			pcall(function()
				animal:setSaddled(false)
			end)
			pcall(animal.update, animal, 0, 0, 0)
			model:PivotTo(CFrame.Angles(0, -math.pi / 2, 0)) -- (facing +x: seen side on from +z)
			local box, size = model:GetBoundingBox()
			local at = Vector3.new(x + size.X / 2, HEIGHT, z)
			model:PivotTo(CFrame.new(at - Vector3.new(box.X, box.Y - size.Y / 2, box.Z)) * model:GetPivot().Rotation)
			model:SetAttribute("LineupScale", model:GetScale()) -- (what it was built at: lineup_read compares)
			model.Archivable = false
			model.Parent = lineup
			local tag = label(model.PrimaryPart, kind .. "  x" .. (Config.AnimalScale[kind] or 1), size)
			tag.Parent = model
			x += size.X + GAP
			count += 1
		end
	end
	local rowTag = Instance.new("Part")
	rowTag.Name = row.name
	rowTag.Anchored = true
	rowTag.Transparency = 1
	rowTag.CanCollide = false
	rowTag.Size = Vector3.new(1, 1, 1)
	rowTag.Position = Vector3.new(-14, HEIGHT + 6, z)
	rowTag.Archivable = false
	label(rowTag, row.name, Vector3.new(0, 0, 0)).Parent = rowTag
	rowTag.Parent = lineup
	widest = math.max(widest, x)
end

local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.Color = Color3.fromRGB(120, 124, 132)
floor.Material = Enum.Material.SmoothPlastic
floor.Size = Vector3.new(widest + 60, 1, #rows * ROW_GAP + 40)
floor.Position = Vector3.new(widest / 2, HEIGHT - 0.5, -(#rows - 1) * ROW_GAP / 2)
floor.Archivable = false
floor.Parent = lineup
lineup.Parent = workspace
Shared:Destroy()

local camera = workspace.CurrentCamera
local look = Vector3.new(widest / 2, HEIGHT, -(#rows - 1) * ROW_GAP / 2)
camera.CFrame = CFrame.lookAt(look + Vector3.new(0, 160, 260), look)
camera.Focus = CFrame.new(look)
return "lineup: " .. count .. " animals in " .. #rows .. " rows"
