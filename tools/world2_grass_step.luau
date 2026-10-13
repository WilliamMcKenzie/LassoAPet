-- World 2's base and first biome step up (QM, Oct 13): the light yellow grass (Ground) a
-- stud above the dark (Grass, at 0), the dirt a stud below. Run in Studio (Edit) after
-- tools/world2_base.luau and world2_meadow_ground.luau (which lay it all flat but the dirt),
-- on the World 2 Place (workspace.World) or World 1's copy (World2, x + 1000).
-- Not under the pens (their floors are at 0: the ground there stays flat out to the
-- biggest pen, 22 tiles a side), nor the start line's row. What stands on it is lifted
-- with it: tools/world2_base_decor.luau (run after) seats everything on the tile below.
local ROOT = workspace:FindFirstChild("World2") or workspace.World
local OFF = if ROOT.Name == "World2" then Vector3.new(1000, 0, 0) else Vector3.zero
local EDGE = -2168 -- the first biome's far end
local PEN_REACH, PEN_RADIUS = 50, 64 -- the biggest pen's middle from its gate, and its half diagonal

local pens = {}
for _, pen in workspace.Pens:GetChildren() do
	local spawn, tiles = pen:FindFirstChild("Spawn"), pen:FindFirstChild("Tiles")
	if spawn and tiles then
		local along = (tiles.Position - spawn.Position) * Vector3.new(1, 0, 1)
		table.insert(pens, spawn.Position + OFF + along.Unit * PEN_REACH)
	end
end
local function underPen(p)
	for _, c in pens do
		if ((p.Position - c) * Vector3.new(1, 0, 1)).Magnitude < PEN_RADIUS then
			return true
		end
	end
	return false
end

local n = 0
for _, p in ROOT.Ground:GetChildren() do
	if p.Name == "Ground" and p.Position.Z > EDGE and p.Position.Z < -8 and not underPen(p)
		or p.Name == "Ground" and p.Position.Z >= 8 and not underPen(p) then
		local bottom = p.Position.Y - p.Size.Y / 2
		local top = 1
		if math.abs(p.Position.Y + p.Size.Y / 2 - top) > 0.01 then
			p.Size = Vector3.new(p.Size.X, top - bottom, p.Size.Z)
			p.Position = Vector3.new(p.Position.X, (top + bottom) / 2, p.Position.Z)
			n += 1
		end
	end
end
return n .. " light grass tiles raised"
