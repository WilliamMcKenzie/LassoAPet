-- The Halloween world's Pumpkin Patch (QM, Oct 15: its third biome, "like a meadow", endless:
-- Config's World 4 block), on the Tundra's old stretch. Its obstacles keep their models (name,
-- invisible Base footprint, tier: smashed as before) but their pines and rocks become the
-- orange Halloween props (ServerStorage.HalloweenProps, tools/halloween_props.luau), each
-- a set size (about as big as the Soul Valley's), facing the middle and turned towards the
-- riders coming in; its floor, walls and tops painted as Config paints them in game.
-- Run in Studio (Edit) on the Halloween Place, after tools/halloween_props.luau. Re-running is fine.
local rgb = Color3.fromRGB
local W = workspace.World
local Z0, Z1 = -2168 - 1816, -2168 - 1816 - 1920 -- the Patch
local props = game:GetService("ServerStorage"):WaitForChild("HalloweenProps")

-- What each obstacle becomes, in turn: { prop, "height" or "wide", studs }
local SWAP = {
	Pine = { { "LanternTree", "height", 55 }, { "SpookyTree", "height", 55 }, { "Scarecrow", "height", 30 } },
	RockBoulder = { { "PumpkinPile", "wide", 40 } },
	RockCrag = { { "JackOLantern", "height", 33 } },
	RockPebble = { { "Pumpkin", "wide", 16 }, { "JackOLanternSmall", "wide", 16 }, { "HayBale", "wide", 14 } },
	RockStone = { { "HayStack", "wide", 26 }, { "LeafPile", "wide", 22 } },
}
-- Which way each one's front looks in its own mesh (x, z): faces -z, the trees' lanterns +x
local FRONT = { SpookyTree = Vector2.new(1, 0), LanternTree = Vector2.new(1, 0) }
local FRONT_ALL = Vector2.new(0, -1)
local TILT = math.rad(30) -- (turned towards the riders coming from the base, QM Oct 15)
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
		local like
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p ~= base then
				like = like or p
			end
		end
		local prop = props[pick[1]]:Clone()
		local _, size = prop:GetBoundingBox()
		local k = if pick[2] == "height" then pick[3] / size.Y else pick[3] / math.max(size.X, size.Z)
		prop:ScaleTo(prop:GetScale() * k)
		-- its footprint: about its trunk's or its body's (60% of its narrower side)
		local _, now = prop:GetBoundingBox()
		local foot = math.min(now.X, now.Z) * (if pick[2] == "height" then 0.35 else 0.6)
		local bottom = base.Position.Y - base.Size.Y / 2
		base.Size = Vector3.new(foot, base.Size.Y, foot)
		base.Position = Vector3.new(base.Position.X, bottom + base.Size.Y / 2, base.Position.Z)
		local front = FRONT[pick[1]] or FRONT_ALL
		local toward = if base.Position.X > 0 then math.pi - TILT else TILT
		local jitter = math.rad(((counts[model.Name] * 53) % 21) - 10)
		local yaw = math.atan2(front.Y, front.X) - toward + jitter -- (CFrame.Angles(0, a, 0) turns angle phi to phi - a)
		local hit = workspace:Raycast(Vector3.new(base.Position.X, 60, base.Position.Z), Vector3.new(0, -120, 0), params)
		prop:PivotTo(CFrame.new(base.Position.X, if hit then hit.Position.Y else 0, base.Position.Z) * CFrame.Angles(0, yaw, 0))
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
	Ground = { rgb(70, 108, 58), rgb(64, 100, 52) },
	Grass = { rgb(58, 90, 48), rgb(52, 84, 44) },
	Ice = { rgb(104, 72, 52), rgb(96, 66, 48) },
	Wall = { rgb(63, 38, 77), rgb(74, 44, 87) },
}
local CAP = rgb(240, 140, 40)
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
return string.format("%d obstacles swapped, %d floor parts, %d wall parts", swapped, floor, walls)
