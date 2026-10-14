-- World 3 (QM, Oct 14): one of every rock design in a line along the base's left wall, for QM to
-- recolour and decorate with (lines from the front, starting at the left wall, a new one before the
-- back wall). World.BaseDecor.RockLineup; re-running replaces it.
local AS = game:GetService("AssetService")
local SS = game:GetService("ServerStorage")
local studs = game:GetService("MaterialService"):FindFirstChild("StudsHalf", true)
local FOSSIL = Color3.fromRGB(159, 161, 172)
local old = workspace.World.BaseDecor:FindFirstChild("RockLineup")
if old then old:Destroy() end
local folder = Instance.new("Folder")
folder.Name = "RockLineup"
folder.Parent = workspace.World.BaseDecor
local designs = {}
-- the base rocks (tools/arc_base.py MESHES), one mesh each, at the base's 2.5x
for name, id in { Pebble = 97909332868672, Stone = 116242154122535, Pillar = 79713364061574, Boulder = 109133145406087, Twins = 121967427061110, Slab = 118417030739444, Crag = 105444261900626, Cliff = 102261747583883 } do
	table.insert(designs, { name = "Base" .. name, ids = { id }, scale = 2.5 })
end
-- the course rocks (tools/biome_rocks.luau PIECES), several pieces each
for name, ids in { Pebble = { 97909332868672 }, Stone = { 112802048248632, 82884921728711 }, Slab = { 77459657567159, 75443554074464 }, Boulder = { 89116112106227, 121000971017571 }, Crag = { 116203642190808, 137285736622590, 79842203430013, 116412510279796, 111736026009275 } } do
	table.insert(designs, { name = "Course" .. name, ids = ids, scale = ({ Pebble = 2.8, Stone = 2.4, Slab = 1.9, Boulder = 2.2, Crag = 1.7 })[name] })
end
table.sort(designs, function(a, b) return a.name < b.name end)
-- rocks already in the place
for _, path in { { "W3BaseDecorRemoved", "RockCrag" }, { "W3BaseDecorRemoved", "RockBoulder" }, { "World3Assets", "PirateCove", "SkullRock" }, { "World3Assets", "Candyland", "ChocolateRocks" }, { "World2Assets", "TempleStone" }, { "World2Assets", "TempleStoneTwin" }, { "World2Assets", "RunestoneShort" }, { "World2Assets", "RunestoneTall" } } do
	local at = SS
	for _, n in path do at = at and at:FindFirstChild(n) end
	if at then table.insert(designs, { name = path[#path], clone = at }) end
end
local z, x, colW, made = 30, -195, 0, 0
for _, d in designs do
	local model = Instance.new("Model")
	model.Name = d.name
	if d.clone then
		local c = d.clone:Clone()
		if c:IsA("BasePart") then c.Parent = model else for _, k in c:GetChildren() do k.Parent = model end c:Destroy() end
	else
		for _, id in d.ids do
			local ok, part = pcall(function() return AS:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id)) end)
			if ok then
				part.Anchored = true
				part.Size *= d.scale
				part.Position *= d.scale
				part.Color = FOSSIL
				if studs then part.Material = studs.BaseMaterial; part.MaterialVariant = "StudsHalf" end
				part.Name = d.name
				part.Parent = model
			end
		end
	end
	for _, p in model:GetDescendants() do if p:IsA("BasePart") then p.Anchored = true end end
	if #model:GetChildren() > 0 then
		model.Parent = folder
		local cf, size = model:GetBoundingBox()
		local half = math.max(size.X, size.Z) / 2
		if z + 2 * half > 300 then -- (the back wall: start the next line further in)
			x += colW + 12; z, colW = 30, 0
		end
		colW = math.max(colW, 2 * half)
		z += half
		model:PivotTo(model:GetPivot() + Vector3.new(x + half - cf.X, 1 - (cf.Y - size.Y / 2), z - cf.Z))
		z += half + 8
		made += 1
	else
		model:Destroy()
	end
end
return made .. " rock designs in lines from x -195 to " .. math.floor(x + colW)
