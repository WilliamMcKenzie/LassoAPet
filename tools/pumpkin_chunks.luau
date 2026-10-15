-- The Pumpkin Patch's floor as four roadwork chunks (QM, Oct 15: "design like 4 chunks and we
-- will randomly pick ones and lay them down like roadwork"). Made by tools/pumpkin_chunks.py:
-- edit that and re-make this, not this. Run in Studio (Edit, execute_luau) on the Halloween
-- Place. Re-running is fine (it rebuilds the folder).
-- Builds ReplicatedStorage.PumpkinPatchChunks.Chunk1..4 (the clients lay them: Client/Endless): each a Model of floor parts 256
-- studs long, the course's width where the Pumpkin Patch starts (outer columns under the
-- walls). Any chunk can follow any other: the seams match. Each Model's pivot is the middle
-- of its start edge at floor height, facing down the course (-z), so the next chunk goes at
-- pivot * CFrame.new(0, 0, -LENGTH). Parts are named Ground (tan), Grass (green), Dirt
-- (brown) for WorldColors; World 4's Pumpkin Patch needs those three in Config.
-- Each chunk is dressed too (QM, Oct 15: the harvest props and the pumpkins, "thoughtful
-- placements"): little scenes against the walls taking turns side to side every 64 studs (an
-- orchard tree with hay and pumpkins, a scarecrow on bales, a pumpkin pile with jack-o-lanterns,
-- a hay stack), a loose pumpkin or leaves opposite each, the middle kept clear to ride. Copies of
-- ServerStorage.HalloweenProps (as stored), in each chunk's Props folder, facing in from their
-- wall and turned 30 degrees back toward the riders. The big ones (tree, scarecrow, hay stack,
-- pumpkin pile) carry an invisible "Base" footprint and a Tier attribute, like the course's
-- Obstacles, for the runtime to make them smashable.
local rgb = Color3.fromRGB
local LENGTH = 256
local LOOK = {
	Ground = { rgb(214, 184, 134), rgb(204, 174, 124) },
	Grass = { rgb(136, 156, 104), rgb(126, 146, 96) },
	Dirt = { rgb(160, 112, 74), rgb(148, 102, 66) },
}
-- per chunk: { name, low x, low z, size x, size z } (z from 0 at the start edge, going -z)
local CHUNKS = {
	{ -- Chunk1
		{ "Grass", -88, -32, 16, 32 },
		{ "Dirt", -88, -48, 32, 16 },
		{ "Grass", -88, -96, 16, 48 },
		{ "Dirt", -88, -128, 16, 32 },
		{ "Grass", -88, -144, 16, 16 },
		{ "Dirt", -88, -240, 16, 96 },
		{ "Grass", -88, -256, 32, 16 },
		{ "Grass", -72, -16, 16, 16 },
		{ "Dirt", -72, -32, 16, 16 },
		{ "Dirt", -72, -96, 16, 48 },
		{ "Grass", -72, -112, 16, 16 },
		{ "Dirt", -72, -144, 16, 32 },
		{ "Grass", -72, -160, 16, 16 },
		{ "Dirt", -72, -176, 16, 16 },
		{ "Grass", -72, -224, 16, 48 },
		{ "Dirt", -72, -240, 16, 16 },
		{ "Ground", -56, -192, 16, 192 },
		{ "Dirt", -56, -208, 16, 16 },
		{ "Ground", -56, -256, 96, 48 },
		{ "Ground", -40, -80, 80, 80 },
		{ "Grass", -40, -112, 16, 32 },
		{ "Ground", -40, -208, 64, 96 },
		{ "Ground", -24, -112, 64, 32 },
		{ "Ground", 24, -192, 16, 80 },
		{ "Dirt", 24, -208, 16, 16 },
		{ "Ground", 40, -32, 16, 32 },
		{ "Grass", 40, -48, 16, 16 },
		{ "Ground", 40, -96, 16, 48 },
		{ "Dirt", 40, -112, 16, 16 },
		{ "Ground", 40, -160, 16, 48 },
		{ "Grass", 40, -176, 16, 16 },
		{ "Dirt", 40, -192, 16, 16 },
		{ "Grass", 40, -208, 32, 16 },
		{ "Dirt", 40, -240, 16, 32 },
		{ "Ground", 40, -256, 16, 16 },
		{ "Grass", 56, -16, 32, 16 },
		{ "Dirt", 56, -48, 16, 32 },
		{ "Grass", 56, -112, 16, 64 },
		{ "Dirt", 56, -144, 16, 32 },
		{ "Grass", 56, -160, 16, 16 },
		{ "Dirt", 56, -176, 16, 16 },
		{ "Grass", 56, -192, 16, 16 },
		{ "Grass", 56, -224, 16, 16 },
		{ "Dirt", 56, -240, 32, 16 },
		{ "Grass", 56, -256, 32, 16 },
		{ "Dirt", 72, -32, 16, 16 },
		{ "Grass", 72, -80, 16, 48 },
		{ "Dirt", 72, -112, 16, 32 },
		{ "Grass", 72, -128, 16, 16 },
		{ "Dirt", 72, -160, 16, 32 },
		{ "Grass", 72, -176, 16, 16 },
		{ "Dirt", 72, -224, 16, 48 },
	},
	{ -- Chunk2
		{ "Grass", -88, -16, 32, 16 },
		{ "Dirt", -88, -48, 16, 32 },
		{ "Grass", -88, -80, 16, 32 },
		{ "Dirt", -88, -96, 32, 16 },
		{ "Grass", -88, -144, 16, 48 },
		{ "Dirt", -88, -160, 16, 16 },
		{ "Grass", -88, -176, 32, 16 },
		{ "Dirt", -88, -192, 16, 16 },
		{ "Grass", -88, -208, 64, 16 },
		{ "Dirt", -88, -224, 32, 16 },
		{ "Grass", -88, -256, 32, 32 },
		{ "Grass", -72, -64, 16, 48 },
		{ "Dirt", -72, -80, 16, 16 },
		{ "Dirt", -72, -144, 16, 48 },
		{ "Grass", -72, -160, 16, 16 },
		{ "Grass", -72, -192, 16, 16 },
		{ "Ground", -56, -16, 112, 16 },
		{ "Grass", -56, -32, 16, 16 },
		{ "Ground", -56, -64, 16, 32 },
		{ "Grass", -56, -80, 16, 16 },
		{ "Ground", -56, -96, 96, 16 },
		{ "Grass", -56, -112, 32, 16 },
		{ "Ground", -56, -128, 96, 16 },
		{ "Dirt", -56, -144, 16, 16 },
		{ "Ground", -56, -192, 96, 48 },
		{ "Grass", -56, -240, 16, 32 },
		{ "Ground", -56, -256, 112, 16 },
		{ "Ground", -40, -48, 96, 32 },
		{ "Grass", -40, -64, 16, 16 },
		{ "Ground", -40, -80, 80, 16 },
		{ "Ground", -40, -144, 80, 16 },
		{ "Ground", -40, -240, 80, 32 },
		{ "Ground", -24, -64, 64, 16 },
		{ "Ground", -24, -112, 64, 16 },
		{ "Ground", -24, -208, 64, 16 },
		{ "Grass", 40, -80, 16, 32 },
		{ "Dirt", 40, -160, 16, 80 },
		{ "Grass", 40, -192, 48, 32 },
		{ "Dirt", 40, -224, 16, 32 },
		{ "Ground", 40, -240, 16, 16 },
		{ "Grass", 56, -16, 32, 16 },
		{ "Dirt", 56, -64, 16, 48 },
		{ "Grass", 56, -128, 16, 64 },
		{ "Dirt", 56, -144, 16, 16 },
		{ "Grass", 56, -160, 32, 16 },
		{ "Grass", 56, -224, 32, 32 },
		{ "Dirt", 56, -240, 16, 16 },
		{ "Grass", 56, -256, 32, 16 },
		{ "Grass", 72, -48, 16, 32 },
		{ "Dirt", 72, -128, 16, 80 },
		{ "Grass", 72, -144, 16, 16 },
		{ "Grass", 72, -240, 16, 16 },
	},
	{ -- Chunk3
		{ "Grass", -88, -48, 16, 48 },
		{ "Dirt", -88, -64, 48, 16 },
		{ "Grass", -88, -80, 16, 16 },
		{ "Dirt", -88, -96, 48, 16 },
		{ "Grass", -88, -128, 32, 32 },
		{ "Dirt", -88, -176, 16, 48 },
		{ "Grass", -88, -256, 16, 80 },
		{ "Grass", -72, -16, 16, 16 },
		{ "Dirt", -72, -32, 16, 16 },
		{ "Grass", -72, -48, 16, 16 },
		{ "Dirt", -72, -80, 16, 16 },
		{ "Dirt", -72, -144, 32, 16 },
		{ "Grass", -72, -160, 16, 16 },
		{ "Dirt", -72, -176, 16, 16 },
		{ "Grass", -72, -192, 32, 16 },
		{ "Dirt", -72, -224, 16, 32 },
		{ "Grass", -72, -256, 16, 32 },
		{ "Ground", -56, -32, 112, 32 },
		{ "Dirt", -56, -48, 16, 16 },
		{ "Ground", -56, -80, 112, 16 },
		{ "Grass", -56, -112, 16, 16 },
		{ "Dirt", -56, -128, 16, 16 },
		{ "Ground", -56, -176, 112, 32 },
		{ "Dirt", -56, -208, 16, 16 },
		{ "Ground", -56, -256, 16, 48 },
		{ "Ground", -40, -64, 64, 32 },
		{ "Ground", -40, -144, 80, 64 },
		{ "Ground", -40, -208, 96, 32 },
		{ "Dirt", -40, -224, 16, 16 },
		{ "Grass", -40, -240, 16, 16 },
		{ "Ground", -40, -256, 96, 16 },
		{ "Ground", -24, -240, 64, 32 },
		{ "Ground", 24, -48, 32, 16 },
		{ "Dirt", 24, -64, 16, 16 },
		{ "Grass", 40, -64, 48, 16 },
		{ "Dirt", 40, -112, 16, 32 },
		{ "Grass", 40, -128, 48, 16 },
		{ "Ground", 40, -144, 16, 16 },
		{ "Dirt", 40, -224, 48, 16 },
		{ "Grass", 40, -240, 48, 16 },
		{ "Grass", 56, -48, 16, 48 },
		{ "Dirt", 56, -96, 16, 32 },
		{ "Grass", 56, -112, 16, 16 },
		{ "Grass", 56, -192, 16, 64 },
		{ "Dirt", 56, -208, 32, 16 },
		{ "Grass", 56, -256, 32, 16 },
		{ "Grass", 72, -32, 16, 32 },
		{ "Dirt", 72, -48, 16, 16 },
		{ "Grass", 72, -96, 16, 32 },
		{ "Dirt", 72, -112, 16, 16 },
		{ "Dirt", 72, -144, 16, 16 },
		{ "Grass", 72, -192, 16, 48 },
	},
	{ -- Chunk4
		{ "Grass", -88, -32, 32, 32 },
		{ "Dirt", -88, -64, 16, 32 },
		{ "Grass", -88, -144, 16, 80 },
		{ "Dirt", -88, -160, 16, 16 },
		{ "Grass", -88, -176, 48, 16 },
		{ "Dirt", -88, -192, 32, 16 },
		{ "Grass", -88, -256, 16, 64 },
		{ "Grass", -72, -96, 16, 64 },
		{ "Dirt", -72, -128, 16, 32 },
		{ "Grass", -72, -160, 16, 32 },
		{ "Dirt", -72, -224, 16, 32 },
		{ "Grass", -72, -256, 16, 32 },
		{ "Ground", -56, -16, 112, 16 },
		{ "Grass", -56, -32, 32, 16 },
		{ "Ground", -56, -48, 112, 16 },
		{ "Grass", -56, -64, 16, 16 },
		{ "Dirt", -56, -80, 16, 16 },
		{ "Grass", -56, -112, 16, 32 },
		{ "Dirt", -56, -128, 32, 16 },
		{ "Grass", -56, -144, 16, 16 },
		{ "Dirt", -56, -160, 16, 16 },
		{ "Grass", -56, -208, 16, 32 },
		{ "Dirt", -56, -224, 16, 16 },
		{ "Ground", -56, -256, 96, 32 },
		{ "Ground", -40, -96, 80, 48 },
		{ "Grass", -40, -112, 16, 16 },
		{ "Ground", -40, -192, 80, 64 },
		{ "Grass", -40, -224, 16, 32 },
		{ "Ground", -24, -32, 64, 16 },
		{ "Ground", -24, -128, 64, 32 },
		{ "Ground", -24, -224, 80, 32 },
		{ "Dirt", 40, -32, 32, 16 },
		{ "Ground", 40, -80, 16, 32 },
		{ "Dirt", 40, -96, 16, 16 },
		{ "Grass", 40, -112, 32, 16 },
		{ "Dirt", 40, -128, 16, 16 },
		{ "Grass", 40, -144, 16, 16 },
		{ "Ground", 40, -192, 16, 48 },
		{ "Dirt", 40, -240, 16, 16 },
		{ "Ground", 40, -256, 16, 16 },
		{ "Grass", 56, -16, 32, 16 },
		{ "Grass", 56, -64, 16, 32 },
		{ "Dirt", 56, -80, 16, 16 },
		{ "Grass", 56, -96, 32, 16 },
		{ "Grass", 56, -128, 32, 16 },
		{ "Dirt", 56, -160, 16, 32 },
		{ "Grass", 56, -176, 32, 16 },
		{ "Dirt", 56, -192, 16, 16 },
		{ "Grass", 56, -256, 16, 64 },
		{ "Grass", 72, -32, 16, 16 },
		{ "Dirt", 72, -64, 16, 32 },
		{ "Grass", 72, -80, 16, 16 },
		{ "Dirt", 72, -112, 16, 16 },
		{ "Dirt", 72, -144, 16, 16 },
		{ "Grass", 72, -160, 16, 16 },
		{ "Grass", 72, -192, 16, 16 },
		{ "Dirt", 72, -224, 16, 32 },
		{ "Grass", 72, -256, 16, 32 },
	},
}

-- per chunk: { item, x, z, yaw degrees, tier (0 = decor) } (yaw: CFrame.Angles on a model facing -z)
local PROPS = {
	{ -- Chunk1
		{ "LanternTree", -61.4, -35.0, -120, 3 },
		{ "HayStack", -70.5, -20.0, -120, 2 },
		{ "Pumpkin", -62.9, -26.0, -140, 0 },
		{ "LeafScatter", -56.9, -39.0, -120, 0 },
		{ "Pumpkin", -69.9, -47.0, -105, 0 },
		{ "LeafScatter", 68.0, -23.0, 315, 0 },
		{ "Scarecrow", 67.9, -101.0, 120, 2 },
		{ "HayBale", 71.9, -109.0, 120, 0 },
		{ "HayBale", 67.9, -109.0, 210, 0 },
		{ "JackOLanternSmall", 62.9, -94.0, 130, 0 },
		{ "LeafScatter", 59.9, -100.0, 120, 0 },
		{ "Pumpkin", 70.2, -90.0, 120, 0 },
		{ "Pumpkin", -68.9, -92.0, 15, 0 },
		{ "PumpkinPile", -68.5, -161.0, -120, 2 },
		{ "JackOLantern", -63.9, -171.0, -120, 0 },
		{ "Pumpkin", -62.9, -152.0, -145, 0 },
		{ "LeafPile", -60.9, -158.0, -120, 0 },
		{ "JackOLanternSmall", -70.9, -148.0, -120, 0 },
		{ "LeafPile", 67.9, -156.0, 240, 0 },
		{ "HayStack", 70.5, -224.0, 120, 2 },
		{ "HayBale", 64.9, -233.0, 150, 0 },
		{ "HayBale", 71.9, -233.0, 120, 0 },
		{ "Pumpkin", 64.9, -216.0, 120, 0 },
		{ "JackOLanternSmall", 62.9, -226.0, 110, 0 },
		{ "LeafScatter", 57.9, -214.0, 120, 0 },
		{ "JackOLanternSmall", -66.9, -224.0, 45, 0 },
	},
	{ -- Chunk2
		{ "Scarecrow", 67.9, -32.0, 120, 2 },
		{ "HayBale", 71.9, -24.0, 120, 0 },
		{ "HayBale", 67.9, -24.0, 210, 0 },
		{ "JackOLanternSmall", 62.9, -39.0, 130, 0 },
		{ "LeafScatter", 59.9, -33.0, 120, 0 },
		{ "Pumpkin", 70.2, -43.0, 120, 0 },
		{ "Pumpkin", -70.9, -22.0, 270, 0 },
		{ "LanternTree", -61.4, -96.0, -120, 3 },
		{ "HayStack", -70.5, -111.0, -120, 2 },
		{ "Pumpkin", -62.9, -105.0, -140, 0 },
		{ "LeafScatter", -56.9, -92.0, -120, 0 },
		{ "Pumpkin", -69.9, -84.0, -105, 0 },
		{ "LeafPile", 67.9, -104.0, 120, 0 },
		{ "HayStack", 70.5, -164.0, 120, 2 },
		{ "HayBale", 64.9, -173.0, 150, 0 },
		{ "HayBale", 71.9, -173.0, 120, 0 },
		{ "Pumpkin", 64.9, -156.0, 120, 0 },
		{ "JackOLanternSmall", 62.9, -166.0, 110, 0 },
		{ "LeafScatter", 57.9, -154.0, 120, 0 },
		{ "JackOLanternSmall", -68.9, -165.0, 300, 0 },
		{ "PumpkinPile", -68.5, -224.0, -120, 2 },
		{ "JackOLantern", -63.9, -214.0, -120, 0 },
		{ "Pumpkin", -62.9, -233.0, -145, 0 },
		{ "LeafPile", -60.9, -227.0, -120, 0 },
		{ "JackOLanternSmall", -70.9, -237.0, -120, 0 },
		{ "LeafScatter", 67.9, -229.0, 300, 0 },
	},
	{ -- Chunk3
		{ "PumpkinPile", -68.5, -30.0, -120, 2 },
		{ "JackOLantern", -63.9, -20.0, -120, 0 },
		{ "Pumpkin", -62.9, -39.0, -145, 0 },
		{ "LeafPile", -60.9, -33.0, -120, 0 },
		{ "JackOLanternSmall", -70.9, -43.0, -120, 0 },
		{ "LeafPile", 67.9, -18.0, 225, 0 },
		{ "HayStack", 70.5, -99.0, 120, 2 },
		{ "HayBale", 64.9, -108.0, 150, 0 },
		{ "HayBale", 71.9, -108.0, 120, 0 },
		{ "Pumpkin", 64.9, -91.0, 120, 0 },
		{ "JackOLanternSmall", 62.9, -101.0, 110, 0 },
		{ "LeafScatter", 57.9, -89.0, 120, 0 },
		{ "JackOLanternSmall", -65.9, -102.0, 300, 0 },
		{ "LanternTree", -61.4, -163.0, -120, 3 },
		{ "HayStack", -70.5, -148.0, -120, 2 },
		{ "Pumpkin", -62.9, -154.0, -140, 0 },
		{ "LeafScatter", -56.9, -167.0, -120, 0 },
		{ "Pumpkin", -69.9, -175.0, -105, 0 },
		{ "LeafScatter", 66.9, -165.0, 60, 0 },
		{ "Scarecrow", 67.9, -222.0, 120, 2 },
		{ "HayBale", 71.9, -214.0, 120, 0 },
		{ "HayBale", 67.9, -214.0, 210, 0 },
		{ "JackOLanternSmall", 62.9, -229.0, 130, 0 },
		{ "LeafScatter", 59.9, -223.0, 120, 0 },
		{ "Pumpkin", 70.2, -233.0, 120, 0 },
		{ "Pumpkin", -66.9, -229.0, 285, 0 },
	},
	{ -- Chunk4
		{ "HayStack", 70.5, -26.0, 120, 2 },
		{ "HayBale", 64.9, -35.0, 150, 0 },
		{ "HayBale", 71.9, -35.0, 120, 0 },
		{ "Pumpkin", 64.9, -18.0, 120, 0 },
		{ "JackOLanternSmall", 62.9, -28.0, 110, 0 },
		{ "LeafScatter", 57.9, -16.0, 120, 0 },
		{ "JackOLanternSmall", -70.9, -26.0, 135, 0 },
		{ "PumpkinPile", -68.5, -92.0, -120, 2 },
		{ "JackOLantern", -63.9, -82.0, -120, 0 },
		{ "Pumpkin", -62.9, -101.0, -145, 0 },
		{ "LeafPile", -60.9, -95.0, -120, 0 },
		{ "JackOLanternSmall", -70.9, -105.0, -120, 0 },
		{ "LeafScatter", 69.8, -90.0, 180, 0 },
		{ "Scarecrow", 67.9, -155.0, 120, 2 },
		{ "HayBale", 71.9, -147.0, 120, 0 },
		{ "HayBale", 67.9, -147.0, 210, 0 },
		{ "JackOLanternSmall", 62.9, -162.0, 130, 0 },
		{ "LeafScatter", 59.9, -156.0, 120, 0 },
		{ "Pumpkin", 70.2, -166.0, 120, 0 },
		{ "Pumpkin", -68.9, -169.0, 210, 0 },
		{ "LanternTree", -61.4, -228.0, -120, 3 },
		{ "HayStack", -70.5, -213.0, -120, 2 },
		{ "Pumpkin", -62.9, -219.0, -140, 0 },
		{ "LeafScatter", -56.9, -232.0, -120, 0 },
		{ "Pumpkin", -69.9, -240.0, -105, 0 },
		{ "LeafPile", 69.0, -237.0, 165, 0 },
	},
}
-- If the props turn out facing the wall instead of the riders, set this to 180.
local YAW_OFFSET = 0

local SS = game:GetService("ServerStorage")
local old = SS:FindFirstChild("PumpkinPatchChunks")
if old then
	old:Destroy()
end
local RS = game:GetService("ReplicatedStorage")
local folder = RS:FindFirstChild("PumpkinPatchChunks") or Instance.new("Folder")
folder.Name = "PumpkinPatchChunks"
folder.Parent = RS
folder:ClearAllChildren()
-- The floor's look off a floor part: its material and both its textures (the studs, and the
-- "Checker" WorldColors knows by name)
local floorLike
for _, p in workspace.World.Ground:GetChildren() do
	if p:FindFirstChild("Checker") and p:FindFirstChildWhichIsA("Texture") ~= nil and #p:GetChildren() >= 2 then
		floorLike = p
		break
	end
end
assert(floorLike, "no floor part with its studs and Checker to copy")
-- The walls and their tops: the long straight ones down the Tundra's old stretch, cut to a chunk
local wallLike = {}
for _, p in workspace.World.Walls:GetChildren() do
	if p.Size.Z > 400 and p.Position.Z < -3984 and p.Position.Z > -5904 then
		table.insert(wallLike, p)
	end
end
assert(#wallLike >= 4, "no Tundra walls to copy")
local parts, placed, missing = 0, 0, {}
for n, list in CHUNKS do
	local model = Instance.new("Model")
	model.Name = "Chunk" .. n
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
	root.Transparency = 1
	root.Size = Vector3.new(1, 1, 1)
	root.CFrame = CFrame.new(0, 0, 0)
	root.Parent = model
	model.PrimaryPart = root
	for _, r in list do
		local p = Instance.new("Part")
		p.Name = r[1]
		p.Anchored = true
		p.Material = floorLike.Material
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Size = Vector3.new(r[4], 2, r[5])
		p.CFrame = CFrame.new(r[2] + r[4] / 2, -1, r[3] + r[5] / 2)
		p.Color = LOOK[r[1]][1]
		for _, tex in floorLike:GetChildren() do
			if tex:IsA("Texture") then
				local t = tex:Clone()
				t.Color3 = LOOK[r[1]][2]
				t.Parent = p
			end
		end
		p.Parent = model
		parts += 1
	end
	for _, w in wallLike do
		local c = w:Clone()
		c.Size = Vector3.new(c.Size.X, c.Size.Y, LENGTH)
		c.CFrame = CFrame.new(w.Position.X, w.Position.Y, -LENGTH / 2) * w.CFrame.Rotation
		if c.Name == "Cap" then
			c.Color = Color3.fromRGB(240, 140, 40) -- (Config's World 4 Pumpkin Patch CapColor)
		else
			c.Color = Color3.fromRGB(63, 38, 77) -- (its WallColors)
			for _, t in c:GetChildren() do
				if t:IsA("Texture") then
					t.Color3 = Color3.fromRGB(74, 44, 87)
				end
			end
		end
		c.Parent = model
	end
	local dressing = Instance.new("Folder")
	dressing.Name = "Props"
	dressing.Parent = model
	for _, q in PROPS[n] do
		local source = SS.HalloweenProps:FindFirstChild(q[1])
		if not source then
			table.insert(missing, q[1])
			continue
		end
		local prop = source:Clone()
		prop:PivotTo(CFrame.new(q[2], 0, q[3]) * CFrame.Angles(0, math.rad(q[4] + YAW_OFFSET), 0))
		-- (the props' pivot is their foot, their pieces' shared origin: already on the floor)
		local cf, size
		for _, p in prop:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = true
			end
		end
		if q[5] > 0 then
			cf, size = prop:GetBoundingBox()
			local base = Instance.new("Part")
			base.Name = "Base"
			base.Anchored, base.CanCollide, base.CanQuery, base.CanTouch = true, false, false, false
			base.Transparency = 1
			base.Size = Vector3.new(size.X, 1, size.Z)
			base.CFrame = CFrame.new(cf.X, 0.5, cf.Z)
			base.Parent = prop
			prop:SetAttribute("Tier", q[5])
		end
		prop.Parent = dressing
		placed += 1
	end
	model:SetAttribute("Length", LENGTH)
	model.Parent = folder
end
return string.format("%d chunks, %d parts, each %d long; %d props placed%s", #CHUNKS, parts, LENGTH, placed,
	if #missing > 0 then ", missing from ServerStorage.HalloweenProps: " .. table.concat(missing, ", ") else "")
