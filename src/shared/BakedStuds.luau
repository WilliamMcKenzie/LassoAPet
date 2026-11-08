-- The studs baked into the baseplate grid (QM, Nov 8, memory and lag: ~23,000 fewer Textures).
-- A face that wore a grid ("Checker") Texture and a stud Texture wears one picture of both
-- (tools/bake_stud_grid.py), untinted: the grid Texture keeps its tiling and offsets, takes
-- the baked image, and the stud Texture goes. Only the three looks the map has are baked:
--   ground tops     Roblox's Baseplate + 1-stud studs   (Floor)
--   ground sides    the 2x2 grid + 1-stud studs          (FloorSide)
--   anything else   the 2x2 grid + 2-stud studs          (Wall: walls, caps)
-- Anything else (a grid with no studs, a non-ground Baseplate top) keeps its Textures.
-- workspace.StudStyle no longer changes baked faces: re-run the tool for other values.
-- Only the home base wears the grid (QM, Nov 8): outside it mergeAll gives faces back the
-- biome-coloured checker and studs they had before (a baked face splits into the two), and
-- Client/Endless builds those.
--
--   BakedStuds.merge(part, ground) -> how many faces it baked
--   BakedStuds.plain(part, ground) -> the grid off its faces: the coloured checker + studs instead
--   BakedStuds.mergeAll(world)     -> merge in the home base, plain everywhere else

local BakedStuds = {}

local CHECKER = "rbxassetid://6372755229" -- Roblox's Baseplate texture (Server/Map)
local WALL_CHECKER = "rbxassetid://119843983644581" -- assets/terrain/Baseplate2x2.png
local STUD = "rbxassetid://7447638591"
local StudStyle = require(script.Parent.StudStyle)

-- uploaded pictures (assets/terrain/StudGrid*.png); "" bakes nothing of that look
BakedStuds.IDS = {
	Floor = "rbxassetid://114916306273885", -- StudGridFloor.png (base checker 20% softer, Nov 8)
	FloorSide = "rbxassetid://137345544596451", -- StudGridFloorSide.png (the same)
	Wall = "rbxassetid://114582520270896", -- StudGridWall.png
}
-- (earlier uploads of the same looks: still on a place baked before, swapped for IDS')
local OLD = {
	["rbxassetid://97799538921027"] = "Floor",
	["rbxassetid://115934859193770"] = "FloorSide",
}

function BakedStuds.merge(part, ground)
	local grids, studs
	for _, t in part:GetChildren() do
		if t:IsA("Texture") then
			if t.Texture == STUD then
				studs = studs or {}
				studs[t.Face] = t
			elseif t.Texture == CHECKER or t.Texture == WALL_CHECKER then
				grids = grids or {}
				grids[t.Face] = t
			end
		end
	end
	if not grids or not studs then
		return 0
	end
	local n = 0
	for face, grid in grids do
		local stud = studs[face]
		if not stud then
			continue
		end
		local id
		if grid.Texture == CHECKER then
			id = if ground then BakedStuds.IDS.Floor else nil
		else
			id = if ground then BakedStuds.IDS.FloorSide else BakedStuds.IDS.Wall
		end
		if not id or id == "" then
			continue
		end
		grid.Texture = id
		grid.Color3 = Color3.new(1, 1, 1)
		grid.Transparency = 0
		grid.ZIndex = 1
		stud:Destroy()
		n += 1
	end
	return n
end

local function baked(id)
	for look, v in BakedStuds.IDS do
		if v == id then
			return look
		end
	end
	return OLD[id]
end

-- the biome-coloured checker outside the base (as Server/Map had it before the baseplate)
local COLOUR_CHECKER = "rbxassetid://84747779882944"
local Config = require(script.Parent.Config)
-- (the map editor's colours first, as Server/Map paints: Config's are only defaults, and in
-- Edit mode there's no live workspace.WorldColors; in Play WorldColors repaints by ColorKey)
local mapColours
local function colour(key)
	if not mapColours then
		local ok, data = pcall(require, script.Parent.MapData)
		mapColours = if ok and type(data) == "table" and data.Colours then data.Colours else {}
	end
	local c = mapColours[key]
	if type(c) == "table" then
		return Color3.fromRGB(c[1], c[2], c[3])
	end
	return Config.WorldColors[key]
end

-- a grid Texture (or a baked face's) -> the coloured checker: same 8-stud tiling and offsets
-- (Server/Map lined both up the same way), tinted by the part's ColorKey .. "Checker";
-- false when the part's colour has no checker
local function recolour(t, part)
	local key = part:GetAttribute("ColorKey")
	local c = typeof(key) == "string" and colour(key .. "Checker")
	if not c then
		return false
	end
	t.Texture = COLOUR_CHECKER
	t.Name = "Checker"
	t.StudsPerTileU, t.StudsPerTileV = 8, 8
	t.ZIndex = 1
	t.Color3 = c
	t:SetAttribute("ColorKey", key .. "Checker")
	t.Transparency = if part:GetAttribute("Lava") then 0.55 elseif part:GetAttribute("Liquid") then 0.5 else 0
	return true
end

-- Outside the base: no baseplate grid, the biome-coloured checker and the studs over it
-- (QM, Nov 8), as the map was before. A baked face splits back into the two.
function BakedStuds.plain(part, ground)
	local n = 0
	for _, t in part:GetChildren() do
		if not t:IsA("Texture") then
			continue
		end
		local look = baked(t.Texture)
		if look then
			-- the studs it held: a stud Texture again, as Server/Map makes it; StudStyle
			-- scales it (walls' 2-stud studs) and lines it up with the world grid
			local stud = Instance.new("Texture")
			stud.Name = "Studs"
			stud.Face = t.Face
			stud.Texture = STUD
			stud.StudsPerTileU, stud.StudsPerTileV = 1, 1
			stud.OffsetStudsU, stud.OffsetStudsV = t.OffsetStudsU % 1, t.OffsetStudsV % 1
			stud.ZIndex = 2
			stud.Parent = part
			StudStyle.apply(stud, ground)
		end
		if t.Texture == COLOUR_CHECKER then
			recolour(t, part) -- (an earlier pass's: painted again from the map's colours)
		elseif look or t.Texture == CHECKER or t.Texture == WALL_CHECKER then
			if not recolour(t, part) then
				t:Destroy()
			end
			n += 1
		end
	end
	-- (a face whose grid an earlier pass took off, leaving only its studs, or a liquid's
	-- bare top: its coloured checker back, lined up as Server/Map lines it)
	if part.ClassName ~= "Part" then
		return n
	end
	local want, have = {}, {}
	for _, t in part:GetChildren() do
		if t:IsA("Texture") then
			if t.Texture == STUD then
				want[t.Face] = true
			elseif t.Texture == COLOUR_CHECKER then
				have[t.Face] = true
			end
		end
	end
	if part:GetAttribute("Liquid") and part.Name:sub(-7) == "Surface" then
		want[Enum.NormalId.Top] = true
	end
	local aligned = part.CFrame.Rotation:FuzzyEq(CFrame.identity)
	local corner, far = part.Position - part.Size / 2, part.Position + part.Size / 2
	for face in want do
		if have[face] then
			continue
		end
		local t = Instance.new("Texture")
		t.Face = face
		if not recolour(t, part) then
			t:Destroy()
			continue
		end
		if aligned then
			if face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
				t.OffsetStudsU, t.OffsetStudsV = (4 - far.X) % 8, (4 - far.Z) % 8
			elseif face == Enum.NormalId.Front or face == Enum.NormalId.Back then
				t.OffsetStudsU, t.OffsetStudsV = corner.X % 8, corner.Y % 8
			else
				t.OffsetStudsU, t.OffsetStudsV = corner.Z % 8, corner.Y % 8
			end
		end
		t.Parent = part
		n += 1
	end
	return n
end

-- (in the home base: the Floor's Base folder, a Base wall or ring wall, or World.Base)
local function inBase(part, world)
	local at = part.Parent
	while at and at ~= world do
		local area = at:GetAttribute("Area")
		if area ~= nil then
			return area == "Base"
		end
		if at.Name == "Base" or at.Name == "BaseWall" or at.Name == "BaseRingWall" then
			return true
		end
		at = at.Parent
	end
	return false
end

function BakedStuds.mergeAll(world)
	local floor = world:FindFirstChild("Floor")
	local n = 0
	for _, part in world:GetDescendants() do
		if part:IsA("BasePart") then
			local ground = floor ~= nil and part:IsDescendantOf(floor)
			if inBase(part, world) then
				for _, t in part:GetChildren() do
					local look = t:IsA("Texture") and OLD[t.Texture]
					if look and BakedStuds.IDS[look] ~= "" then
						t.Texture = BakedStuds.IDS[look] -- (the gentler checker, QM Nov 8)
					end
				end
				n += BakedStuds.merge(part, ground)
			else
				n += BakedStuds.plain(part, ground)
			end
		end
	end
	return n
end

return BakedStuds
