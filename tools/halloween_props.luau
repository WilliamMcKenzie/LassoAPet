-- The Halloween world's props (QM, Oct 15: "spooky tree with lantern hanging, jack o lanterns,
-- pumpkins, autumn leaves on the ground"), from design/w3_halloween (claude/world3-props-mo84d8
-- a3163ed): each item's pieces/<Name>_<i>.obj, the tree at 2x and the rest at 1.5x, uploaded
-- as meshes (meshup.py). Builds one Model per item in ServerStorage.HalloweenProps, the
-- pieces sharing their origin, studded like the other props; the lantern glass and the faces
-- glow (Neon). Not placed anywhere yet. Run in Studio (Edit) on the Halloween Place; re-running is fine.
local AssetService = game:GetService("AssetService")
local rgb = Color3.fromRGB
local GLOW = rgb(255, 214, 60)
local ITEMS = { -- [item] = { { label, mesh id, colour } } (pieces/colours.txt)
	JackOLantern = {
		{ "Pumpkin", 108933514207456, rgb(206, 70, 18) },
		{ "Pumpkin", 77537202979253, rgb(172, 54, 14) },
		{ "Stem", 135965151139018, rgb(104, 120, 46) },
		{ "Face", 140516797003942, rgb(255, 214, 60) },
	},
	JackOLanternSmall = {
		{ "Pumpkin", 121764506896385, rgb(206, 70, 18) },
		{ "Pumpkin", 101579942969128, rgb(172, 54, 14) },
		{ "Stem", 115606687725223, rgb(104, 120, 46) },
		{ "Face", 102589937463543, rgb(255, 214, 60) },
	},
	LeafPile = {
		{ "Leaves", 98046589917614, rgb(214, 52, 40) },
		{ "Leaves", 98607740192829, rgb(252, 200, 50) },
		{ "Leaves", 75104593151077, rgb(150, 80, 40) },
	},
	LeafScatter = {
		{ "Leaves", 94015664686448, rgb(214, 52, 40) },
		{ "Leaves", 80705177317307, rgb(252, 200, 50) },
		{ "Leaves", 72911466969362, rgb(150, 80, 40) },
	},
	Pumpkin = {
		{ "Pumpkin", 108822732459066, rgb(206, 70, 18) },
		{ "Pumpkin", 100010004325226, rgb(172, 54, 14) },
		{ "Stem", 140077196349641, rgb(104, 120, 46) },
	},
	PumpkinPile = {
		{ "Pumpkin", 132320840488383, rgb(206, 70, 18) },
		{ "Pumpkin", 111003502623798, rgb(172, 54, 14) },
		{ "Stem", 76852132141378, rgb(104, 120, 46) },
	},
	SpookyTree = {
		{ "Trunk", 88894980825285, rgb(96, 64, 58) },
		{ "Branches", 114835250997847, rgb(74, 50, 50) },
		{ "Lantern", 103170069508437, rgb(52, 46, 58) },
		{ "Glass", 133660742363798, rgb(255, 214, 60) },
	},
}
local SS = game:GetService("ServerStorage")
local folder = SS:FindFirstChild("HalloweenProps") or Instance.new("Folder")
folder.Name = "HalloweenProps"
folder.Parent = SS
local studs = game:GetService("MaterialService"):FindFirstChild("StudsHalf", true)
local made, failed = 0, {}
for item, pieces in ITEMS do
	local old = folder:FindFirstChild(item)
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = item
	for i, piece in pieces do
		local ok, part = pcall(AssetService.CreateMeshPartAsync, AssetService, Content.fromUri("rbxassetid://" .. piece[2]),
			{ RenderFidelity = Enum.RenderFidelity.Precise, CollisionFidelity = Enum.CollisionFidelity.Box })
		if not ok then
			table.insert(failed, item .. "_" .. i)
			continue
		end
		part.Name = piece[1]
		part:SetAttribute("Piece", i) -- (its place in pieces/colours.txt: the names repeat)
		part.Anchored = true
		part.Position = Vector3.zero -- (the mesh's own origin: the pieces share it)
		part.Color = piece[3]
		local glows = piece[1] == "Glass" or piece[1] == "Face"
		if glows then
			part.Material = Enum.Material.Neon
			part.Color = GLOW
			part.CastShadow = false
		elseif studs then
			part.Material = studs.BaseMaterial
			part.MaterialVariant = "StudsHalf"
		end
		part.CanCollide = item ~= "LeafPile" and item ~= "LeafScatter" and not glows
		part.Parent = model
		made += 1
	end
	if #model:GetChildren() > 0 then
		model.PrimaryPart = model:GetChildren()[1]
		model.Parent = folder
	end
end
return string.format("%d pieces in %d models%s%s", made, #folder:GetChildren(),
	if studs then "" else ", no StudsHalf variant", if #failed > 0 then ", failed: " .. table.concat(failed, " ") else "")
