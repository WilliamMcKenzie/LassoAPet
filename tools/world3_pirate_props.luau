-- World 3's pirate props (QM, Oct 14; design/pirate on claude/rock-meshes-ggc7md): one Model
-- per item in ServerStorage.PirateProps, its pieces' MeshParts at the mesh origin (base y=0,
-- facing -z), studded (StudsHalf) and coloured from pieces/colours.txt. Rerunnable.
local AssetService = game:GetService("AssetService")
local PIECES = {
	{ "BarrelGroup_1", "Barrel", 100566992923439, 188, 118, 62 },
	{ "BarrelGroup_2", "Hoops", 75965717922896, 86, 88, 98 },
	{ "BarrelGroup_3", "Lid", 125043551353871, 150, 92, 48 },
	{ "Barrel_1", "Barrel", 114524225461922, 188, 118, 62 },
	{ "Barrel_2", "Hoops", 78161288106203, 86, 88, 98 },
	{ "Barrel_3", "Lid", 106860906293495, 150, 92, 48 },
	{ "CrateStack_1", "Crate", 101140956947726, 214, 160, 92 },
	{ "CrateStack_2", "Frame", 127958703804694, 156, 104, 56 },
	{ "Crate_1", "Crate", 115850781741439, 214, 160, 92 },
	{ "Crate_2", "Frame", 88249208694465, 156, 104, 56 },
	{ "PalmTreeSmall_1", "Trunk", 122426000934087, 186, 134, 80 },
	{ "PalmTreeSmall_2", "Trunk", 90511748416329, 158, 108, 62 },
	{ "PalmTreeSmall_3", "Fronds", 99500360728648, 84, 176, 52 },
	{ "PalmTreeSmall_4", "Fronds", 71129173459040, 112, 198, 64 },
	{ "PalmTreeSmall_5", "Coconuts", 72799685534058, 112, 72, 40 },
	{ "PalmTree_1", "Trunk", 99808729024646, 186, 134, 80 },
	{ "PalmTree_2", "Trunk", 90764732062237, 158, 108, 62 },
	{ "PalmTree_3", "Fronds", 109196007060782, 84, 176, 52 },
	{ "PalmTree_4", "Fronds", 101932241612867, 112, 198, 64 },
	{ "PalmTree_5", "Coconuts", 93187689323776, 112, 72, 40 },
	{ "PirateShip_1", "Hull", 72373038784816, 132, 78, 42 },
	{ "PirateShip_2", "Stripe", 73557482137276, 252, 210, 64 },
	{ "PirateShip_3", "Deck", 101394452241231, 210, 160, 100 },
	{ "PirateShip_4", "Rails", 107319817538748, 104, 60, 32 },
	{ "PirateShip_5", "Ports", 80244357312627, 34, 28, 26 },
	{ "PirateShip_6", "Masts", 90673009872545, 118, 72, 40 },
	{ "PirateShip_7", "Sails", 112593930876825, 248, 244, 230 },
	{ "PirateShip_8", "Flag", 133529203891803, 28, 28, 34 },
	{ "PirateShip_9", "Crossbones", 80514960689497, 250, 250, 250 }
}
local folder = game.ServerStorage:FindFirstChild("PirateProps")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "PirateProps"
local variant = game:GetService("MaterialService"):FindFirstChild("StudsHalf")
local models, made, failed = {}, 0, {}
for _, p in PIECES do
	local item = p[1]:match("^(.-)_%d+$")
	local model = models[item]
	if not model then
		model = Instance.new("Model")
		model.Name = item
		model.Parent = folder
		models[item] = model
	end
	local ok, part = pcall(function()
		return AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. p[3]))
	end)
	if ok then
		part.Name = p[2]
		part.Anchored = true
		part.Color = Color3.fromRGB(p[4], p[5], p[6])
		if variant then
			part.Material = variant.BaseMaterial
			part.MaterialVariant = "StudsHalf"
		end
		part.Parent = model
		made += 1
	else
		table.insert(failed, p[1] .. ": " .. tostring(part))
	end
end
local sizes = {}
for name, model in models do
	model.WorldPivot = CFrame.new()
	local cf, s = model:GetBoundingBox()
	table.insert(sizes, string.format("%s %.1fx%.1fx%.1f at y%.1f", name, s.X, s.Y, s.Z, cf.Position.Y - s.Y / 2))
end
folder.Parent = game.ServerStorage
return made .. " pieces; " .. table.concat(sizes, ", ") .. (#failed > 0 and ("; FAILED " .. table.concat(failed, "; ")) or "")
