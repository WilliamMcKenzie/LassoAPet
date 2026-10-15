-- The Pumpkin Patch's floor as four roadwork chunks (QM, Oct 15: "design like 4 chunks and we
-- will randomly pick ones and lay them down like roadwork"). Made by tools/pumpkin_chunks.py:
-- edit that and re-make this, not this. Run in Studio (Edit, execute_luau) on the Halloween
-- Place. Re-running is fine (it rebuilds the folder).
-- Builds ServerStorage.PumpkinPatchChunks.Chunk1..4: each a Model of floor parts 256
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
		{ "Grass", -88, -32, 24, 32 },
		{ "Dirt", -88, -48, 24, 16 },
		{ "Grass", -88, -96, 16, 48 },
		{ "Dirt", -88, -128, 24, 32 },
		{ "Grass", -88, -144, 24, 16 },
		{ "Dirt", -88, -240, 16, 96 },
		{ "Grass", -88, -256, 32, 16 },
		{ "Dirt", -72, -80, 16, 32 },
		{ "Grass", -72, -96, 24, 16 },
		{ "Dirt", -72, -160, 16, 16 },
		{ "Grass", -72, -208, 8, 48 },
		{ "Dirt", -72, -240, 16, 32 },
		{ "Grass", -64, -16, 8, 16 },
		{ "Ground", -64, -48, 112, 32 },
		{ "Dirt", -64, -120, 8, 24 },
		{ "Ground", -64, -144, 120, 24 },
		{ "Ground", -64, -208, 104, 48 },
		{ "Ground", -56, -16, 104, 16 },
		{ "Ground", -56, -80, 96, 32 },
		{ "Dirt", -56, -112, 8, 16 },
		{ "Grass", -56, -120, 8, 8 },
		{ "Ground", -56, -160, 104, 16 },
		{ "Ground", -56, -256, 112, 48 },
		{ "Ground", -48, -120, 88, 40 },
		{ "Ground", 40, -72, 8, 24 },
		{ "Grass", 40, -88, 16, 16 },
		{ "Ground", 40, -120, 16, 32 },
		{ "Ground", 40, -176, 8, 16 },
		{ "Grass", 40, -208, 16, 32 },
		{ "Ground", 48, -8, 8, 8 },
		{ "Grass", 48, -72, 8, 64 },
		{ "Grass", 48, -176, 24, 32 },
		{ "Grass", 56, -16, 32, 16 },
		{ "Dirt", 56, -32, 32, 16 },
		{ "Grass", 56, -80, 16, 48 },
		{ "Dirt", 56, -96, 16, 16 },
		{ "Ground", 56, -136, 8, 40 },
		{ "Grass", 56, -144, 8, 8 },
		{ "Grass", 56, -192, 32, 16 },
		{ "Dirt", 56, -216, 16, 24 },
		{ "Ground", 56, -232, 8, 16 },
		{ "Grass", 56, -256, 32, 24 },
		{ "Grass", 64, -128, 8, 32 },
		{ "Dirt", 64, -144, 24, 16 },
		{ "Grass", 64, -232, 24, 16 },
		{ "Dirt", 72, -80, 16, 48 },
		{ "Grass", 72, -96, 16, 16 },
		{ "Dirt", 72, -112, 16, 16 },
		{ "Grass", 72, -128, 16, 16 },
		{ "Dirt", 72, -160, 16, 16 },
		{ "Grass", 72, -176, 16, 16 },
		{ "Grass", 72, -216, 16, 24 },
	},
	{ -- Chunk2
		{ "Grass", -88, -16, 32, 16 },
		{ "Dirt", -88, -48, 16, 32 },
		{ "Grass", -88, -80, 16, 32 },
		{ "Dirt", -88, -96, 32, 16 },
		{ "Grass", -88, -144, 16, 48 },
		{ "Dirt", -88, -160, 16, 16 },
		{ "Grass", -88, -176, 40, 16 },
		{ "Dirt", -88, -192, 16, 16 },
		{ "Grass", -88, -208, 24, 16 },
		{ "Dirt", -88, -224, 16, 16 },
		{ "Grass", -88, -256, 32, 32 },
		{ "Grass", -72, -48, 16, 32 },
		{ "Dirt", -72, -80, 16, 32 },
		{ "Dirt", -72, -128, 24, 32 },
		{ "Grass", -72, -160, 24, 32 },
		{ "Grass", -72, -192, 16, 16 },
		{ "Grass", -72, -224, 16, 16 },
		{ "Ground", -64, -208, 120, 16 },
		{ "Ground", -56, -40, 16, 40 },
		{ "Grass", -56, -48, 32, 8 },
		{ "Dirt", -56, -64, 8, 16 },
		{ "Ground", -56, -88, 112, 24 },
		{ "Grass", -56, -96, 8, 8 },
		{ "Grass", -56, -184, 8, 8 },
		{ "Ground", -56, -192, 120, 8 },
		{ "Ground", -56, -256, 88, 48 },
		{ "Ground", -48, -64, 104, 16 },
		{ "Ground", -48, -144, 96, 56 },
		{ "Grass", -48, -160, 8, 16 },
		{ "Ground", -48, -184, 104, 24 },
		{ "Ground", -40, -32, 80, 32 },
		{ "Grass", -40, -40, 16, 8 },
		{ "Ground", -40, -160, 96, 16 },
		{ "Ground", -24, -48, 72, 16 },
		{ "Ground", 32, -216, 8, 8 },
		{ "Grass", 32, -232, 24, 16 },
		{ "Ground", 32, -256, 24, 24 },
		{ "Ground", 40, -16, 16, 16 },
		{ "Dirt", 40, -32, 16, 16 },
		{ "Grass", 40, -216, 16, 8 },
		{ "Grass", 48, -40, 40, 8 },
		{ "Ground", 48, -48, 8, 8 },
		{ "Grass", 48, -120, 8, 32 },
		{ "Ground", 48, -144, 8, 24 },
		{ "Grass", 56, -32, 32, 32 },
		{ "Grass", 56, -80, 32, 40 },
		{ "Dirt", 56, -96, 16, 16 },
		{ "Grass", 56, -128, 16, 32 },
		{ "Ground", 56, -152, 8, 24 },
		{ "Grass", 56, -160, 32, 8 },
		{ "Dirt", 56, -184, 16, 24 },
		{ "Ground", 56, -200, 8, 8 },
		{ "Dirt", 56, -240, 16, 40 },
		{ "Grass", 56, -256, 32, 16 },
		{ "Grass", 64, -152, 8, 24 },
		{ "Dirt", 64, -200, 24, 16 },
		{ "Grass", 72, -112, 16, 32 },
		{ "Dirt", 72, -144, 16, 32 },
		{ "Grass", 72, -152, 16, 8 },
		{ "Grass", 72, -176, 16, 16 },
		{ "Dirt", 72, -184, 16, 8 },
		{ "Dirt", 72, -208, 16, 8 },
		{ "Grass", 72, -240, 16, 32 },
	},
	{ -- Chunk3
		{ "Grass", -88, -48, 16, 48 },
		{ "Dirt", -88, -64, 40, 16 },
		{ "Grass", -88, -80, 16, 16 },
		{ "Dirt", -88, -96, 16, 16 },
		{ "Grass", -88, -128, 16, 32 },
		{ "Dirt", -88, -176, 16, 48 },
		{ "Grass", -88, -256, 16, 80 },
		{ "Grass", -72, -32, 16, 32 },
		{ "Dirt", -72, -48, 16, 16 },
		{ "Dirt", -72, -80, 16, 16 },
		{ "Grass", -72, -112, 16, 32 },
		{ "Dirt", -72, -128, 16, 16 },
		{ "Grass", -72, -144, 16, 16 },
		{ "Dirt", -72, -160, 16, 16 },
		{ "Grass", -72, -184, 8, 24 },
		{ "Dirt", -72, -208, 16, 24 },
		{ "Grass", -72, -256, 16, 48 },
		{ "Grass", -64, -168, 16, 8 },
		{ "Ground", -64, -184, 16, 16 },
		{ "Ground", -56, -16, 112, 16 },
		{ "Grass", -56, -48, 8, 32 },
		{ "Ground", -56, -88, 104, 24 },
		{ "Grass", -56, -112, 8, 24 },
		{ "Ground", -56, -128, 104, 16 },
		{ "Dirt", -56, -144, 24, 16 },
		{ "Grass", -56, -160, 24, 16 },
		{ "Ground", -56, -224, 96, 40 },
		{ "Grass", -56, -240, 8, 16 },
		{ "Ground", -56, -256, 112, 16 },
		{ "Ground", -48, -64, 72, 48 },
		{ "Ground", -48, -112, 96, 24 },
		{ "Dirt", -48, -176, 16, 16 },
		{ "Ground", -48, -184, 96, 8 },
		{ "Ground", -48, -240, 96, 16 },
		{ "Ground", -32, -176, 80, 48 },
		{ "Grass", 24, -32, 64, 16 },
		{ "Ground", 24, -64, 8, 32 },
		{ "Grass", 32, -40, 40, 8 },
		{ "Ground", 32, -64, 16, 24 },
		{ "Ground", 40, -208, 8, 24 },
		{ "Dirt", 40, -224, 48, 16 },
		{ "Grass", 48, -208, 8, 168 },
		{ "Grass", 48, -232, 40, 8 },
		{ "Ground", 48, -240, 8, 8 },
		{ "Grass", 56, -16, 32, 16 },
		{ "Grass", 56, -48, 16, 8 },
		{ "Dirt", 56, -80, 16, 32 },
		{ "Grass", 56, -96, 16, 16 },
		{ "Dirt", 56, -128, 16, 32 },
		{ "Grass", 56, -144, 16, 16 },
		{ "Dirt", 56, -160, 32, 16 },
		{ "Grass", 56, -208, 16, 48 },
		{ "Grass", 56, -256, 32, 24 },
		{ "Dirt", 72, -64, 16, 32 },
		{ "Grass", 72, -80, 16, 16 },
		{ "Dirt", 72, -96, 16, 16 },
		{ "Grass", 72, -128, 16, 32 },
		{ "Dirt", 72, -144, 16, 16 },
		{ "Grass", 72, -176, 16, 16 },
		{ "Dirt", 72, -208, 16, 32 },
	},
	{ -- Chunk4
		{ "Grass", -88, -32, 32, 32 },
		{ "Dirt", -88, -64, 16, 32 },
		{ "Grass", -88, -144, 16, 80 },
		{ "Dirt", -88, -160, 16, 16 },
		{ "Grass", -88, -176, 16, 16 },
		{ "Dirt", -88, -192, 40, 16 },
		{ "Grass", -88, -256, 16, 64 },
		{ "Grass", -72, -80, 16, 48 },
		{ "Dirt", -72, -112, 16, 32 },
		{ "Grass", -72, -160, 24, 48 },
		{ "Dirt", -72, -176, 16, 16 },
		{ "Dirt", -72, -208, 24, 16 },
		{ "Grass", -72, -224, 32, 16 },
		{ "Dirt", -72, -240, 16, 16 },
		{ "Grass", -72, -256, 16, 16 },
		{ "Ground", -56, -8, 112, 8 },
		{ "Grass", -56, -32, 8, 24 },
		{ "Dirt", -56, -48, 16, 16 },
		{ "Grass", -56, -80, 8, 32 },
		{ "Dirt", -56, -96, 8, 16 },
		{ "Grass", -56, -112, 8, 16 },
		{ "Grass", -56, -176, 8, 16 },
		{ "Grass", -56, -248, 8, 24 },
		{ "Ground", -56, -256, 112, 8 },
		{ "Ground", -48, -24, 96, 16 },
		{ "Grass", -48, -32, 16, 8 },
		{ "Grass", -48, -56, 8, 8 },
		{ "Ground", -48, -208, 72, 152 },
		{ "Ground", -48, -248, 96, 24 },
		{ "Grass", -40, -40, 8, 8 },
		{ "Ground", -40, -56, 88, 16 },
		{ "Ground", -40, -224, 80, 16 },
		{ "Ground", -32, -40, 80, 16 },
		{ "Ground", 24, -160, 16, 104 },
		{ "Dirt", 24, -184, 16, 24 },
		{ "Ground", 24, -208, 16, 24 },
		{ "Ground", 40, -80, 8, 24 },
		{ "Dirt", 40, -96, 16, 16 },
		{ "Ground", 40, -160, 8, 64 },
		{ "Grass", 40, -192, 16, 32 },
		{ "Dirt", 40, -208, 16, 16 },
		{ "Grass", 40, -224, 16, 16 },
		{ "Ground", 48, -16, 8, 8 },
		{ "Grass", 48, -32, 40, 16 },
		{ "Dirt", 48, -48, 40, 16 },
		{ "Grass", 48, -80, 24, 32 },
		{ "Grass", 48, -112, 40, 16 },
		{ "Ground", 48, -144, 8, 32 },
		{ "Dirt", 48, -160, 24, 16 },
		{ "Grass", 48, -232, 24, 8 },
		{ "Ground", 48, -248, 8, 16 },
		{ "Grass", 56, -16, 32, 16 },
		{ "Grass", 56, -96, 32, 16 },
		{ "Grass", 56, -144, 16, 32 },
		{ "Dirt", 56, -176, 16, 16 },
		{ "Grass", 56, -208, 32, 32 },
		{ "Dirt", 56, -224, 16, 16 },
		{ "Grass", 56, -256, 16, 24 },
		{ "Dirt", 72, -64, 16, 16 },
		{ "Grass", 72, -80, 16, 16 },
		{ "Dirt", 72, -144, 16, 32 },
		{ "Grass", 72, -176, 16, 32 },
		{ "Grass", 72, -224, 16, 16 },
		{ "Dirt", 72, -240, 16, 16 },
		{ "Grass", 72, -256, 16, 16 },
	},
}

-- per chunk: { item, x, z, yaw degrees, tier (0 = decor) } (yaw: CFrame.Angles on a model facing -z)
local PROPS = {
	{ -- Chunk1
		{ "LanternTree", -64.9, -32.0, -120, 3 },
		{ "HayStack", -70.9, -47.0, -120, 2 },
		{ "Pumpkin", -62.9, -41.0, -140, 0 },
		{ "LeafScatter", -56.9, -28.0, -120, 0 },
		{ "Pumpkin", -69.9, -20.0, -105, 0 },
		{ "LeafScatter", 69.9, -24.0, 0, 0 },
		{ "Scarecrow", 67.9, -96.0, 120, 2 },
		{ "HayBale", 71.9, -104.0, 120, 0 },
		{ "HayBale", 67.9, -104.0, 210, 0 },
		{ "JackOLanternSmall", 62.9, -89.0, 130, 0 },
		{ "LeafScatter", 59.9, -95.0, 120, 0 },
		{ "Pumpkin", 70.9, -85.0, 120, 0 },
		{ "Pumpkin", -69.9, -88.0, 0, 0 },
		{ "PumpkinPile", -69.9, -160.0, -120, 2 },
		{ "JackOLantern", -63.9, -150.0, -120, 0 },
		{ "Pumpkin", -62.9, -169.0, -145, 0 },
		{ "LeafPile", -60.9, -163.0, -120, 0 },
		{ "JackOLanternSmall", -70.9, -173.0, -120, 0 },
		{ "LeafPile", 69.9, -152.0, 0, 0 },
		{ "HayStack", 70.9, -224.0, 120, 2 },
		{ "HayBale", 64.9, -215.0, 150, 0 },
		{ "HayBale", 71.9, -215.0, 120, 0 },
		{ "Pumpkin", 64.9, -232.0, 120, 0 },
		{ "JackOLanternSmall", 62.9, -222.0, 110, 0 },
		{ "LeafScatter", 57.9, -234.0, 120, 0 },
		{ "JackOLanternSmall", -69.9, -216.0, 0, 0 },
	},
	{ -- Chunk2
		{ "Scarecrow", -67.9, -32.0, -120, 2 },
		{ "HayBale", -71.9, -40.0, -120, 0 },
		{ "HayBale", -67.9, -40.0, -210, 0 },
		{ "JackOLanternSmall", -62.9, -25.0, -130, 0 },
		{ "LeafScatter", -59.9, -31.0, -120, 0 },
		{ "Pumpkin", -70.9, -21.0, -120, 0 },
		{ "Pumpkin", 69.9, -40.0, 0, 0 },
		{ "LanternTree", 64.9, -96.0, 120, 3 },
		{ "HayStack", 70.9, -111.0, 120, 2 },
		{ "Pumpkin", 62.9, -105.0, 140, 0 },
		{ "LeafScatter", 56.9, -92.0, 120, 0 },
		{ "Pumpkin", 69.9, -84.0, 105, 0 },
		{ "LeafPile", -69.9, -104.0, 0, 0 },
		{ "HayStack", -70.9, -160.0, -120, 2 },
		{ "HayBale", -64.9, -151.0, -150, 0 },
		{ "HayBale", -71.9, -151.0, -120, 0 },
		{ "Pumpkin", -64.9, -168.0, -120, 0 },
		{ "JackOLanternSmall", -62.9, -158.0, -110, 0 },
		{ "LeafScatter", -57.9, -170.0, -120, 0 },
		{ "JackOLanternSmall", 69.9, -168.0, 0, 0 },
		{ "PumpkinPile", 69.9, -224.0, 120, 2 },
		{ "JackOLantern", 63.9, -214.0, 120, 0 },
		{ "Pumpkin", 62.9, -233.0, 145, 0 },
		{ "LeafPile", 60.9, -227.0, 120, 0 },
		{ "JackOLanternSmall", 70.9, -237.0, 120, 0 },
		{ "LeafScatter", -69.9, -232.0, 0, 0 },
	},
	{ -- Chunk3
		{ "PumpkinPile", -69.9, -32.0, -120, 2 },
		{ "JackOLantern", -63.9, -22.0, -120, 0 },
		{ "Pumpkin", -62.9, -41.0, -145, 0 },
		{ "LeafPile", -60.9, -35.0, -120, 0 },
		{ "JackOLanternSmall", -70.9, -45.0, -120, 0 },
		{ "LeafPile", 69.9, -24.0, 0, 0 },
		{ "HayStack", 70.9, -96.0, 120, 2 },
		{ "HayBale", 64.9, -87.0, 150, 0 },
		{ "HayBale", 71.9, -87.0, 120, 0 },
		{ "Pumpkin", 64.9, -104.0, 120, 0 },
		{ "JackOLanternSmall", 62.9, -94.0, 110, 0 },
		{ "LeafScatter", 57.9, -106.0, 120, 0 },
		{ "JackOLanternSmall", -69.9, -88.0, 0, 0 },
		{ "LanternTree", -64.9, -160.0, -120, 3 },
		{ "HayStack", -70.9, -175.0, -120, 2 },
		{ "Pumpkin", -62.9, -169.0, -140, 0 },
		{ "LeafScatter", -56.9, -156.0, -120, 0 },
		{ "Pumpkin", -69.9, -148.0, -105, 0 },
		{ "LeafScatter", 69.9, -152.0, 0, 0 },
		{ "Scarecrow", 67.9, -224.0, 120, 2 },
		{ "HayBale", 71.9, -232.0, 120, 0 },
		{ "HayBale", 67.9, -232.0, 210, 0 },
		{ "JackOLanternSmall", 62.9, -217.0, 130, 0 },
		{ "LeafScatter", 59.9, -223.0, 120, 0 },
		{ "Pumpkin", 70.9, -213.0, 120, 0 },
		{ "Pumpkin", -69.9, -216.0, 0, 0 },
	},
	{ -- Chunk4
		{ "HayStack", -70.9, -32.0, -120, 2 },
		{ "HayBale", -64.9, -23.0, -150, 0 },
		{ "HayBale", -71.9, -23.0, -120, 0 },
		{ "Pumpkin", -64.9, -40.0, -120, 0 },
		{ "JackOLanternSmall", -62.9, -30.0, -110, 0 },
		{ "LeafScatter", -57.9, -42.0, -120, 0 },
		{ "JackOLanternSmall", 69.9, -40.0, 0, 0 },
		{ "PumpkinPile", 69.9, -96.0, 120, 2 },
		{ "JackOLantern", 63.9, -86.0, 120, 0 },
		{ "Pumpkin", 62.9, -105.0, 145, 0 },
		{ "LeafPile", 60.9, -99.0, 120, 0 },
		{ "JackOLanternSmall", 70.9, -109.0, 120, 0 },
		{ "LeafScatter", -69.9, -104.0, 0, 0 },
		{ "Scarecrow", -67.9, -160.0, -120, 2 },
		{ "HayBale", -71.9, -168.0, -120, 0 },
		{ "HayBale", -67.9, -168.0, -210, 0 },
		{ "JackOLanternSmall", -62.9, -153.0, -130, 0 },
		{ "LeafScatter", -59.9, -159.0, -120, 0 },
		{ "Pumpkin", -70.9, -149.0, -120, 0 },
		{ "Pumpkin", 69.9, -168.0, 0, 0 },
		{ "LanternTree", 64.9, -224.0, 120, 3 },
		{ "HayStack", 70.9, -239.0, 120, 2 },
		{ "Pumpkin", 62.9, -233.0, 140, 0 },
		{ "LeafScatter", 56.9, -220.0, 120, 0 },
		{ "Pumpkin", 69.9, -212.0, 105, 0 },
		{ "LeafPile", -69.9, -232.0, 0, 0 },
	},
}
-- If the props turn out facing the wall instead of the riders, set this to 180.
local YAW_OFFSET = 0

local SS = game:GetService("ServerStorage")
local folder = SS:FindFirstChild("PumpkinPatchChunks") or Instance.new("Folder")
folder.Name = "PumpkinPatchChunks"
folder.Parent = SS
folder:ClearAllChildren()
local checker
for _, p in workspace.World.Ground:GetChildren() do -- (the 4-stud checker, off any floor part)
	checker = checker or p:FindFirstChildWhichIsA("Texture")
end
assert(checker, "no checker Texture on the floor to copy")
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
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Size = Vector3.new(r[4], 2, r[5])
		p.CFrame = CFrame.new(r[2] + r[4] / 2, -1, r[3] + r[5] / 2)
		p.Color = LOOK[r[1]][1]
		local t = checker:Clone()
		t.Face = Enum.NormalId.Top
		t.Color3 = LOOK[r[1]][2]
		t.Parent = p
		p.Parent = model
		parts += 1
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
		local cf, size = prop:GetBoundingBox()
		prop:PivotTo(prop:GetPivot() + Vector3.new(0, -(cf.Y - size.Y / 2), 0)) -- (stood on the floor)
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
