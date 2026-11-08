-- The studs baked into the baseplate grid (QM, Nov 8, memory and lag: ~23,000 fewer Textures).
-- A face that wore a grid ("Checker") Texture and a stud Texture wears one picture of both
-- (tools/bake_stud_grid.py), untinted: the grid Texture keeps its tiling and offsets, takes
-- the baked image, and the stud Texture goes. Only the three looks the map has are baked:
--   ground tops     Roblox's Baseplate + 1-stud studs   (Floor)
--   ground sides    the 2x2 grid + 1-stud studs          (FloorSide)
--   anything else   the 2x2 grid + 2-stud studs          (Wall: walls, caps)
-- Anything else (a grid with no studs, a non-ground Baseplate top) keeps its Textures.
-- workspace.StudStyle no longer changes baked faces: re-run the tool for other values.
-- Only the home base wears the grid (QM, Nov 8): outside it mergeAll takes the grid off and
-- leaves plain studs (a baked face goes back to a stud Texture), and Client/Endless has none.
--
--   BakedStuds.merge(part, ground) -> how many faces it baked
--   BakedStuds.plain(part, ground) -> takes the grid off its faces, leaving the studs
--   BakedStuds.mergeAll(world)     -> merge in the home base, plain everywhere else

local BakedStuds = {}

local CHECKER = "rbxassetid://6372755229" -- Roblox's Baseplate texture (Server/Map)
local WALL_CHECKER = "rbxassetid://119843983644581" -- assets/terrain/Baseplate2x2.png
local STUD = "rbxassetid://7447638591"
local StudStyle = require(script.Parent.StudStyle)

-- uploaded pictures (assets/terrain/StudGrid*.png); "" bakes nothing of that look
BakedStuds.IDS = {
	Floor = "rbxassetid://97799538921027", -- StudGridFloor.png
	FloorSide = "rbxassetid://115934859193770", -- StudGridFloorSide.png
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

function BakedStuds.plain(part, ground)
	local studs = {}
	for _, t in part:GetChildren() do
		if t:IsA("Texture") and t.Texture == STUD then
			studs[t.Face] = true
		end
	end
	local n = 0
	for _, t in part:GetChildren() do
		if not t:IsA("Texture") then
			continue
		end
		local look = baked(t.Texture)
		if t.Texture == CHECKER or t.Texture == WALL_CHECKER or (look and studs[t.Face]) then
			t:Destroy() -- (a grid: its face keeps its own studs, if any)
			n += 1
		elseif look then
			-- a baked face: back to the stud Texture it was, as Server/Map makes it, then
			-- StudStyle scales it (walls' 2-stud studs) and lines it up with the world grid
			t.Texture = STUD
			t.Name = "Studs"
			t.StudsPerTileU, t.StudsPerTileV = 1, 1
			t.OffsetStudsU, t.OffsetStudsV = t.OffsetStudsU % 1, t.OffsetStudsV % 1
			t.Color3 = Color3.new(1, 1, 1)
			t.ZIndex = 2
			t:SetAttribute("ColorKey", nil)
			t:SetAttribute("StudScale", nil)
			StudStyle.apply(t, ground)
			n += 1
		end
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
