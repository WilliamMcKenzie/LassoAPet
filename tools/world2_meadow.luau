-- Run in Studio (Edit, execute_luau) after tools/world2_terrain.luau.
-- World 2's base and first biome painted to QM's reference (Oct 13): marble walls, yellow
-- grass in two shades (the darker next to the dirt, to blend), brown dirt, pale yellow
-- trees and tufts, red flowers. (World 1's ground is tinted at run time by WorldColors;
-- World 2's is painted here, standing alone.)
local W = workspace.World2
local EDGE = -2168 -- the first biome's far end
local rgb = Color3.fromRGB
local GRASS = { rgb(206, 168, 58), rgb(190, 152, 46) } -- part, checker
local GRASS_DARK = { rgb(182, 144, 44), rgb(166, 130, 36) }
local DIRT = { rgb(118, 84, 50), rgb(104, 72, 42) }
local MARBLE = { rgb(236, 232, 224), rgb(218, 214, 206) }
local LEAVES = { rgb(248, 214, 128), rgb(236, 196, 104), rgb(252, 226, 150) }
local TRUNK = rgb(146, 128, 112)
local TUFTS = { rgb(226, 188, 72), rgb(206, 166, 56) }
local STEM = rgb(150, 120, 44)
local PETAL, CENTRE = rgb(222, 52, 46), rgb(255, 212, 64)
local GATE = { rgb(236, 233, 227), rgb(222, 218, 210), rgb(208, 204, 196), rgb(246, 244, 240) }

local function paint(part, pair)
	part.Color = pair[1]
	for _, t in part:GetChildren() do
		if t.Name == "Checker" then
			t.Color3 = pair[2]
		end
	end
end
local function inMeadow(p)
	return p.Position.Z > EDGE
end

-- Dirt first (its boxes in XZ, a little grown, for the darker grass beside it).
local dirt = {}
for _, p in W.Ground:GetChildren() do
	if p.Name == "Dirt" and inMeadow(p) then
		paint(p, DIRT)
		table.insert(dirt, { p.Position - p.Size / 2 - Vector3.new(3, 0, 3), p.Position + p.Size / 2 + Vector3.new(3, 0, 3) })
	end
end
local function nearDirt(p)
	local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
	for _, d in dirt do
		if lo.X < d[2].X and hi.X > d[1].X and lo.Z < d[2].Z and hi.Z > d[1].Z then
			return true
		end
	end
	return false
end
local dark = 0
for _, folder in { W.Ground, W.Funnel } do
	for _, p in folder:GetChildren() do
		if p.Name ~= "Dirt" and inMeadow(p) then
			local near = nearDirt(p)
			dark += if near then 1 else 0
			paint(p, if near then GRASS_DARK else GRASS)
		end
	end
end
for _, p in W.Walls:GetChildren() do
	if inMeadow(p) then
		if p.Name == "Cap" then
			p.Color = GRASS[2]
		else
			paint(p, MARBLE)
		end
	end
end

-- The base's plants (BaseDecor.Plants) and the portal gate.
local function h(c)
	return c:ToHex()
end
for _, m in W.BaseDecor.Plants:GetChildren() do
	for i, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			local c = h(p.Color)
			if m.Name == "Tree" or m.Name == "TreeSmall" then
				p.Color = if c == "7c5638" then TRUNK else LEAVES[(i % #LEAVES) + 1]
			elseif m.Name == "GrassTuft" then
				p.Color = TUFTS[(i % 2) + 1]
			elseif m.Name == "Flower" then
				p.Color = if c == "3a7830" then STEM elseif c == "ffc428" or c == "ffd640" then CENTRE else PETAL
			end
		end
	end
end
for i, p in W.BaseDecor.PortalGate:GetDescendants() do
	if p:IsA("BasePart") then
		p.Color = GATE[(i % #GATE) + 1]
	end
end
return #dirt .. " dirt, " .. dark .. " dark grass"
