-- The base rocks (tools/arc_base.py MESHES: 2.5x, studded, Fossil grey) for the Halloween
-- world (QM, Oct 15: "add in rocks in a lineup also"): a Model each in
-- ServerStorage.HalloweenProps (Rock<Name>), and a row of them behind the props' lineup
-- (Workspace.HalloweenPropsLineup). Run in Studio (Edit) on the Halloween Place; re-running is fine.
local AssetService = game:GetService("AssetService")
local MESHES = {
	{ "Pebble", 97909332868672 }, { "Stone", 116242154122535 }, { "Pillar", 79713364061574 },
	{ "Boulder", 109133145406087 }, { "Twins", 121967427061110 }, { "Slab", 118417030739444 },
	{ "Crag", 105444261900626 }, { "Cliff", 102261747583883 },
}
local SCALE, COLOR, GAP = 2.5, Color3.fromRGB(159, 161, 172), 8
local props = game:GetService("ServerStorage"):FindFirstChild("HalloweenProps")
local lineup = workspace:FindFirstChild("HalloweenPropsLineup")
local studs = game:GetService("MaterialService"):FindFirstChild("StudsHalf", true)
local spawn = workspace.World.SpawnLocation
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.World.Ground }
local made, failed, models, total = 0, {}, {}, 0
for _, m in MESHES do
	local name = "Rock" .. m[1]
	local old = props:FindFirstChild(name)
	if old then old:Destroy() end
	local ok, part = pcall(AssetService.CreateMeshPartAsync, AssetService, Content.fromUri("rbxassetid://" .. m[2]),
		{ RenderFidelity = Enum.RenderFidelity.Precise, CollisionFidelity = Enum.CollisionFidelity.Hull })
	if not ok then
		table.insert(failed, m[1])
		continue
	end
	part.Name = "Rock"
	part.Size *= SCALE
	part.Anchored = true
	part.Color = COLOR
	if studs then
		part.Material = studs.BaseMaterial
		part.MaterialVariant = "StudsHalf"
	end
	local model = Instance.new("Model")
	model.Name = name
	part.Parent = model
	model.PrimaryPart = part
	model.Parent = props
	made += 1
	table.insert(models, model)
	total += part.Size.X + GAP
	local o = lineup and lineup:FindFirstChild(name)
	if o then o:Destroy() end
end
-- the row: 30 studs behind the props', centred on the spawn, each sat on the floor
local z, x = spawn.Position.Z + 60, spawn.Position.X - total / 2
for _, model in models do
	local m = model:Clone()
	local w = m.PrimaryPart.Size.X
	local cx = x + w / 2
	local hit = workspace:Raycast(Vector3.new(cx, 60, z), Vector3.new(0, -120, 0), params)
	m:PivotTo(CFrame.new(cx, 0, z))
	local cf, sz = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(cx - cf.X, (hit and hit.Position.Y or 0) - (cf.Y - sz.Y / 2), z - cf.Z))
	m.Parent = lineup
	x += w + GAP
end
return string.format("%d rocks%s", made, if #failed > 0 then ", failed: " .. table.concat(failed, " ") else "")
