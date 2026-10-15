-- The Halloween world's Desert as a teal night graveyard (QM, Oct 15, from his picture):
--  - ServerStorage.HalloweenPropsNight: the Halloween props (ServerStorage.HalloweenProps,
--    tools/halloween_props.luau) recoloured teal: grey-blue dead tree with a cyan lantern,
--    teal jack-o-lanterns with cyan faces, white and blue pumpkins, teal and blue leaves.
--  - The Desert's obstacles keep their models (name, invisible Base footprint, tier, so
--    they're smashed and scaled as before) but their cacti and rocks are swapped for those
--    props, each sized to what it replaces: cactus > tree, crag > big jack-o-lantern,
--    slab > pumpkin pile, pebble > pumpkin / small jack-o-lantern, stone > leaf pile.
--  - Its floor, walls and wall tops painted as Config's World 4 Desert (so Studio shows it).
-- Run in Studio (Edit) on the Halloween Place, after tools/halloween_props.luau. Re-running is fine.
local rgb = Color3.fromRGB
local SS = game:GetService("ServerStorage")
local W = workspace.World
local Z0, Z1 = -2168, -2168 - 1816 -- the Desert

-- The props' colours: [item] = { [piece index] = colour } (pieces/colours.txt's order)
local GLASS, FACE = rgb(80, 232, 240), rgb(110, 245, 255)
local WHITE, WHITE2, BLUE, BLUE2 = rgb(196, 238, 240), rgb(180, 224, 230), rgb(52, 92, 152), rgb(42, 76, 132)
local TEAL, TEAL2, STEM = rgb(52, 142, 162), rgb(42, 120, 140), rgb(40, 84, 84)
local NIGHT = {
	SpookyTree = { rgb(48, 84, 108), rgb(40, 72, 94), rgb(36, 40, 56), GLASS },
	JackOLantern = { TEAL, TEAL2, STEM, FACE },
	JackOLanternSmall = { TEAL, TEAL2, STEM, FACE },
	PumpkinWhite = { WHITE, WHITE2, rgb(70, 96, 96) },
	PumpkinBlue = { BLUE, BLUE2, STEM },
	PumpkinPile = { BLUE, BLUE2, STEM }, -- (its 1 and 2 are each pumpkin's alternate ribs)
	LeafPile = { rgb(64, 150, 172), rgb(150, 196, 214), rgb(56, 88, 150) },
	LeafScatter = { rgb(64, 150, 172), rgb(150, 196, 214), rgb(56, 88, 150) },
}
local SOURCE = { PumpkinWhite = "Pumpkin", PumpkinBlue = "Pumpkin" }
local props = SS:WaitForChild("HalloweenProps")
local night = SS:FindFirstChild("HalloweenPropsNight") or Instance.new("Folder")
night.Name = "HalloweenPropsNight"
night.Parent = SS
night:ClearAllChildren()
for item, colours in NIGHT do
	local m = props:FindFirstChild(SOURCE[item] or item):Clone()
	m.Name = item
	local pieces = m:GetChildren()
	table.sort(pieces, function(a, b) -- (built in pieces/colours.txt's order; names repeat)
		return (a:GetAttribute("Piece") or 0) < (b:GetAttribute("Piece") or 0)
	end)
	for i, p in pieces do
		if p:IsA("BasePart") then
			p.Color = colours[i] or p.Color
		end
	end
	m.Parent = night
end

-- What each obstacle becomes: { prop, fit } (fit: the prop's height to the old one's, or
-- its widest to the old one's widest for the flat ones)
local SWAP = {
	Cactus = { { "SpookyTree", "height", 1.25 } },
	RockCrag = { { "JackOLantern", "height", 0.7 } },
	RockSlab = { { "PumpkinPile", "wide", 0.9 } },
	RockPebble = { { "PumpkinWhite", "wide", 0.75 }, { "JackOLanternSmall", "wide", 0.75 }, { "PumpkinBlue", "wide", 0.75 } },
	RockStone = { { "LeafPile", "wide", 1 } },
}
-- What they replace measured (x, height, z), before they're scaled in game (ObstacleScale)
local OLD = {
	Cactus = Vector3.new(8.8, 14.7, 8.8), RockCrag = Vector3.new(25.1, 29.6, 26.9), RockSlab = Vector3.new(28.7, 10.4, 17.6),
	RockPebble = Vector3.new(13.6, 7.4, 10), RockStone = Vector3.new(13.3, 10.9, 12.4),
}
-- How much bigger than what they replace, their footprints with them (QM, Oct 15: 1.6x, the
-- trees 3x)
local GROW = { SpookyTree = 3 }
local GROW_ALL = 1.6
-- Which way each one's front looks in its own mesh (x, z): the jack-o-lanterns' faces -z,
-- the tree's lantern +x; QM, Oct 15: all of them roughly facing the middle of the course.
local FRONT = { SpookyTree = Vector2.new(1, 0) }
local FRONT_ALL = Vector2.new(0, -1)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { W.Ground }
local counts, swapped = {}, 0
local models = W.Obstacles:GetChildren()
table.sort(models, function(a, b)
	return a:GetPivot().Position.Z > b:GetPivot().Position.Z
end)
for _, model in models do
	local z = model:GetPivot().Position.Z
	local options = model:IsA("Model") and z < Z0 and z > Z1 and SWAP[model.Name]
	local base = options and model:FindFirstChild("Base")
	if base then
		counts[model.Name] = (counts[model.Name] or 0) + 1
		local pick = options[(counts[model.Name] - 1) % #options + 1]
		-- the old look's box (the desert's own, so re-running doesn't grow them), and its
		-- parts' collision settings
		local like
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p ~= base then
				like = like or p
			end
		end
		local old = OLD[model.Name]
		local prop = night[pick[1]]:Clone()
		local _, size = prop:GetBoundingBox()
		local k = if pick[2] == "height" then old.Y / size.Y else math.max(old.X, old.Z) / math.max(size.X, size.Z)
		local grow = GROW[pick[1]] or GROW_ALL
		prop:ScaleTo(prop:GetScale() * k * pick[3] * grow)
		-- (its footprint grow x the Desert's own, kept on the Base so re-running doesn't grow it again)
		local own = base:GetAttribute("DesertSize") or base.Size
		base:SetAttribute("DesertSize", own)
		local bottom = base.Position.Y - base.Size.Y / 2
		base.Size = Vector3.new(own.X * grow, own.Y, own.Z * grow)
		base.Position = Vector3.new(base.Position.X, bottom + own.Y / 2, base.Position.Z)
		-- facing the middle, give or take 20 degrees; its origin (the props' foot, their pieces'
		-- shared Position) on the floor
		local front = FRONT[pick[1]] or FRONT_ALL
		local toward = if base.Position.X > 0 then math.pi else 0 -- (the angle of -x or +x, in x, z)
		local jitter = math.rad(((counts[model.Name] * 53) % 41) - 20)
		local yaw = math.atan2(front.Y, front.X) - toward + jitter -- (CFrame.Angles(0, a, 0) turns angle phi to phi - a)
		local hit = workspace:Raycast(Vector3.new(base.Position.X, 60, base.Position.Z), Vector3.new(0, -120, 0), params)
		local floor = if hit then hit.Position.Y else 0
		prop:PivotTo(CFrame.new(base.Position.X, floor, base.Position.Z) * CFrame.Angles(0, yaw, 0))
		for _, child in model:GetChildren() do
			if child ~= base then
				child:Destroy()
			end
		end
		for _, p in prop:GetChildren() do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.CanCollide = like and like.CanCollide and p.Material ~= Enum.Material.Neon or false
				p.CanQuery = like and like.CanQuery or false
				p.CanTouch = like and like.CanTouch or false
				p.Parent = model
			end
		end
		prop:Destroy()
		model:SetAttribute("HalloweenProp", pick[1])
		swapped += 1
	end
end

-- the floor, walls and tops, as Config paints them in game
local C = {
	Ground = { rgb(126, 180, 210), rgb(116, 170, 202) },
	Grass = { rgb(86, 122, 150), rgb(78, 114, 142) },
	Stone = { rgb(104, 154, 186), rgb(96, 146, 178) },
	Wall = { rgb(42, 88, 104), rgb(50, 100, 116) },
}
local CAP = rgb(86, 172, 182)
local function paint(p, c)
	p.Color = c[1]
	for _, t in p:GetChildren() do
		if t:IsA("Texture") then
			t.Color3 = c[2]
		end
	end
end
local floor, walls = 0, 0
for _, folder in { W.Ground, W:FindFirstChild("Funnel"), W.Walls } do
	for _, p in folder and folder:GetChildren() or {} do
		if p:IsA("BasePart") and p.Position.Z < Z0 and p.Position.Z > Z1 then
			if p.Name == "Cap" then
				p.Color = CAP
				walls += 1
			elseif C[p.Name] then
				paint(p, C[p.Name])
				if p.Name == "Wall" then walls += 1 else floor += 1 end
			end
		end
	end
end
return string.format("%d night props, %d obstacles swapped, %d floor parts, %d wall parts", #night:GetChildren(), swapped, floor, walls)
