-- World 2's base set (QM, Oct 13: design/pines, the Rock mesh redesign thread): the
-- copied lobby trees become low-poly pines (Pine / PineTall for the big trees, PineSmall
-- for the small ones, at 1x, in the same spots), the rocks take five warm grey shades,
-- tufts go mustard and flowers red with yellow centres and green stems (2x, as the
-- lobby's). Studs throughout. Run in Studio (Edit, execute_luau) on the World 2 Place
-- (ROOT = workspace.World) or on World 1's copy (ROOT = workspace.World2).
local ROOT = workspace:FindFirstChild("World2") or workspace.World
local AssetService = game:GetService("AssetService")
local rgb = Color3.fromRGB

local TRUNK = rgb(144, 125, 114)
local NEEDLES = { rgb(231, 182, 88), rgb(214, 166, 74), rgb(242, 196, 104), rgb(222, 172, 80) }
local PINES = { -- design/pines/pieces (tools/pine_meshes.py): piece 1 is the trunk
	Pine = { 129639745763786, 134328405965946, 127801090979853, 137098710373142, 129217607495851 },
	PineTall = { 119676723278229, 72922718315563, 140024416971821, 132404692065054, 140303392266349, 93345451060917 },
	PineSmall = { 140029582646295, 87590817074105, 125263470195454, 98751142734041 },
}
local ROCKS = { rgb(153, 146, 135), rgb(129, 124, 115), rgb(173, 166, 150), rgb(140, 137, 117), rgb(164, 153, 144) }
local TUFTS = { rgb(231, 182, 88), rgb(214, 166, 74) }
local PETAL, CENTRE, STEM = rgb(222, 52, 56), rgb(255, 196, 40), rgb(58, 120, 48)

local function studs(p)
	p.Material = Enum.Material.Glacier
	p.MaterialVariant = "Studs"
end

local meshes = {} -- [id] = a MeshPart made once, cloned after
local function piece(id)
	if not meshes[id] then
		meshes[id] = AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id))
	end
	return meshes[id]:Clone()
end

local function pine(kind, at, name)
	local m = Instance.new("Model")
	m.Name = name
	for i, id in PINES[kind] do
		local p = piece(id)
		p.Name = kind .. "_" .. i
		p.Anchored = true
		p.CFrame = at -- (each piece's origin is the tree's, base at y = 0)
		p.Color = if i == 1 then TRUNK else NEEDLES[(i - 2) % #NEEDLES + 1]
		studs(p)
		p.Parent = m
	end
	m.WorldPivot = at
	return m
end

local plants = ROOT.BaseDecor.Plants
local trees, big = 0, 0
for _, m in plants:GetChildren() do
	if m.Name == "Tree" or m.Name == "TreeSmall" then
		local at = m:GetPivot()
		local kind = "PineSmall"
		if m.Name == "Tree" then
			big += 1
			kind = if big % 2 == 1 then "Pine" else "PineTall"
		end
		pine(kind, at, kind).Parent = plants
		m:Destroy()
		trees += 1
	elseif m.Name == "GrassTuft" then
		m:ScaleTo(2)
		for i, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				p.Color = TUFTS[i % 2 + 1]
				studs(p)
			end
		end
	elseif m.Name == "Flower" then
		m:ScaleTo(2)
		local k = 0
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				k += 1 -- (the lobby Flower's pieces: stem, petals, centre)
				p.Color = if k == 1 then STEM elseif k == 2 then PETAL else CENTRE
				studs(p)
			end
		end
	end
end
local rocks = 0
for _, p in ROOT.BaseDecor:GetChildren() do
	if p:IsA("BasePart") and (p.Name:match("^Rock") or p.Name == "PortalBoulder" or p.Name == "PortalStone") then
		rocks += 1
		p.Color = ROCKS[(rocks - 1) % #ROCKS + 1]
	end
end
return trees .. " trees to pines, " .. rocks .. " rocks"
