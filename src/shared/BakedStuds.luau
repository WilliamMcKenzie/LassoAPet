-- The studs baked into the baseplate grid (QM, Nov 8, memory and lag: ~23,000 fewer Textures).
-- A face that wore a grid ("Checker") Texture and a stud Texture wears one picture of both
-- (tools/bake_stud_grid.py), untinted: the grid Texture keeps its tiling and offsets, takes
-- the baked image, and the stud Texture goes. Only the three looks the map has are baked:
--   ground tops     Roblox's Baseplate + 1-stud studs   (Floor)
--   ground sides    the 2x2 grid + 1-stud studs          (FloorSide)
--   anything else   the 2x2 grid + 2-stud studs          (Wall: walls, caps)
-- Anything else (a grid with no studs, a non-ground Baseplate top) keeps its Textures.
-- workspace.StudStyle no longer changes baked faces: re-run the tool for other values.
--
--   BakedStuds.merge(part, ground) -> how many faces it baked
--   BakedStuds.mergeAll(world)     -> the same for every part in workspace.World (ground: under its Floor)

local BakedStuds = {}

local CHECKER = "rbxassetid://6372755229" -- Roblox's Baseplate texture (Server/Map)
local WALL_CHECKER = "rbxassetid://119843983644581" -- assets/terrain/Baseplate2x2.png
local STUD = "rbxassetid://7447638591"

-- uploaded pictures (assets/terrain/StudGrid*.png); "" bakes nothing of that look
BakedStuds.IDS = {
	Floor = "",
	FloorSide = "",
	Wall = "",
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

function BakedStuds.mergeAll(world)
	local floor = world:FindFirstChild("Floor")
	local n = 0
	for _, part in world:GetDescendants() do
		if part:IsA("BasePart") then
			n += BakedStuds.merge(part, floor ~= nil and part:IsDescendantOf(floor))
		end
	end
	return n
end

return BakedStuds
