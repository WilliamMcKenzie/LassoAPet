-- World 3's home base as a pirate cove (QM, Oct 14: his reference picture). Made by
-- tools/world3_cove_base.py: edit that and re-make this, not this. Run in Studio (Edit,
-- execute_luau) on the World 3 Place (workspace.World), QM not in Play. Re-running is fine.
-- - Floor: replaces the base's floor parts (World.Ground's Ground, DampSand, WetSand and Water
--   parts in the base, z > 0, not the course's World3Biome ones) with sand and small pools,
--   each copying the look of the old part of its name (checker, water tile). Config colours them.
-- - Cliffs: sandstone blocks along the walls (ServerStorage ... Cliff1..Cliff6, Bush and
--   PalmTreeSmall templates, found by name anywhere under ServerStorage) into World.BaseDecor.Cove.
-- - The old base walls and caps stay as invisible barriers; the sea goes round outside.
-- Leaves the pens, the spawn, the start line, the portal and QM's decor alone.
local W = workspace.World
local SS = game:GetService("ServerStorage")
local SEA_TOP, CLIFF_FOOT = -12, -20
local KINDS = { Ground = true, DampSand = true, WetSand = true, Water = true }
-- { name, low x, low z, size x, size z, top }
local FLOOR = {
	{ "Ground", -216, 0, 136, 320, 1 },
	{ "Ground", -80, 0, 8, 136, 1 },
	{ "DampSand", -80, 136, 4, 36, 0 },
	{ "Ground", -80, 172, 36, 148, 1 },
	{ "DampSand", -76, 136, 24, 4, 0 },
	{ "WetSand", -76, 140, 4, 28, -1 },
	{ "DampSand", -76, 168, 20, 4, 0 },
	{ "Ground", -72, 0, 8, 92, 1 },
	{ "DampSand", -72, 92, 4, 32, 0 },
	{ "Ground", -72, 124, 16, 12, 1 },
	{ "WetSand", -72, 140, 16, 4, -1 },
	{ "Water", -72, 144, 8, 20, -2 },
	{ "WetSand", -72, 164, 12, 4, -1 },
	{ "DampSand", -68, 92, 8, 4, 0 },
	{ "WetSand", -68, 96, 4, 24, -1 },
	{ "DampSand", -68, 120, 16, 4, 0 },
	{ "Ground", -64, 0, 20, 88, 1 },
	{ "DampSand", -64, 88, 28, 4, 0 },
	{ "WetSand", -64, 96, 8, 4, -1 },
	{ "Water", -64, 100, 32, 16, -2 },
	{ "WetSand", -64, 116, 16, 4, -1 },
	{ "Water", -64, 144, 4, 12, -2 },
	{ "WetSand", -64, 156, 4, 8, -1 },
	{ "WetSand", -60, 92, 20, 4, -1 },
	{ "WetSand", -60, 144, 4, 16, -1 },
	{ "DampSand", -60, 160, 4, 8, 0 },
	{ "Water", -56, 96, 12, 4, -2 },
	{ "DampSand", -56, 124, 32, 4, 0 },
	{ "Ground", -56, 128, 36, 8, 1 },
	{ "DampSand", -56, 140, 8, 24, 0 },
	{ "Ground", -56, 164, 4, 8, 1 },
	{ "WetSand", -52, 120, 24, 4, -1 },
	{ "Ground", -52, 136, 32, 4, 1 },
	{ "DampSand", -52, 164, 4, 8, 0 },
	{ "Water", -48, 116, 16, 4, -2 },
	{ "DampSand", -48, 140, 24, 4, 0 },
	{ "WetSand", -48, 144, 4, 24, -1 },
	{ "DampSand", -48, 168, 8, 4, 0 },
	{ "Ground", -44, 0, 4, 48, 1 },
	{ "DampSand", -44, 48, 4, 32, 0 },
	{ "Ground", -44, 80, 40, 8, 1 },
	{ "WetSand", -44, 96, 16, 4, -1 },
	{ "WetSand", -44, 144, 16, 4, -1 },
	{ "Water", -44, 148, 12, 16, -2 },
	{ "WetSand", -44, 164, 8, 4, -1 },
	{ "DampSand", -44, 172, 4, 8, 0 },
	{ "Ground", -44, 180, 216, 140, 1 },
	{ "Ground", -40, 0, 72, 44, 1 },
	{ "DampSand", -40, 44, 4, 8, 0 },
	{ "WetSand", -40, 52, 4, 24, -1 },
	{ "DampSand", -40, 76, 64, 4, 0 },
	{ "DampSand", -40, 92, 16, 4, 0 },
	{ "WetSand", -40, 168, 4, 8, -1 },
	{ "DampSand", -40, 176, 24, 4, 0 },
	{ "DampSand", -36, 44, 28, 4, 0 },
	{ "WetSand", -36, 48, 4, 8, -1 },
	{ "Water", -36, 56, 20, 16, -2 },
	{ "WetSand", -36, 72, 28, 4, -1 },
	{ "Ground", -36, 88, 32, 4, 1 },
	{ "Water", -36, 164, 12, 8, -2 },
	{ "WetSand", -36, 172, 16, 4, -1 },
	{ "WetSand", -32, 48, 20, 4, -1 },
	{ "Water", -32, 52, 16, 4, -2 },
	{ "WetSand", -32, 100, 4, 20, -1 },
	{ "WetSand", -32, 148, 12, 4, -1 },
	{ "Water", -32, 152, 8, 12, -2 },
	{ "DampSand", -28, 96, 4, 28, 0 },
	{ "DampSand", -28, 144, 12, 4, 0 },
	{ "Ground", -24, 92, 4, 36, 1 },
	{ "Ground", -24, 140, 8, 4, 1 },
	{ "WetSand", -24, 152, 4, 20, -1 },
	{ "Ground", -20, 92, 16, 16, 1 },
	{ "DampSand", -20, 108, 4, 32, 0 },
	{ "DampSand", -20, 148, 4, 28, 0 },
	{ "WetSand", -16, 52, 4, 8, -1 },
	{ "Water", -16, 60, 4, 12, -2 },
	{ "DampSand", -16, 108, 32, 4, 0 },
	{ "WetSand", -16, 112, 4, 24, -1 },
	{ "DampSand", -16, 136, 4, 8, 0 },
	{ "Ground", -16, 144, 28, 36, 1 },
	{ "DampSand", -12, 48, 4, 8, 0 },
	{ "WetSand", -12, 56, 4, 16, -1 },
	{ "WetSand", -12, 112, 24, 4, -1 },
	{ "Water", -12, 116, 20, 16, -2 },
	{ "WetSand", -12, 132, 4, 8, -1 },
	{ "DampSand", -12, 140, 20, 4, 0 },
	{ "Ground", -8, 44, 40, 8, 1 },
	{ "DampSand", -8, 52, 4, 24, 0 },
	{ "Water", -8, 132, 8, 4, -2 },
	{ "WetSand", -8, 136, 12, 4, -1 },
	{ "Ground", -4, 52, 36, 24, 1 },
	{ "DampSand", -4, 80, 4, 28, 0 },
	{ "WetSand", 0, 80, 4, 24, -1 },
	{ "DampSand", 0, 104, 24, 4, 0 },
	{ "WetSand", 0, 132, 16, 4, -1 },
	{ "WetSand", 4, 80, 16, 4, -1 },
	{ "Water", 4, 84, 12, 16, -2 },
	{ "WetSand", 4, 100, 16, 4, -1 },
	{ "DampSand", 4, 136, 16, 4, 0 },
	{ "WetSand", 8, 116, 4, 8, -1 },
	{ "Water", 8, 124, 4, 8, -2 },
	{ "Ground", 8, 140, 4, 4, 1 },
	{ "DampSand", 12, 112, 4, 8, 0 },
	{ "WetSand", 12, 120, 4, 12, -1 },
	{ "DampSand", 12, 140, 4, 32, 0 },
	{ "Ground", 12, 172, 204, 8, 1 },
	{ "WetSand", 16, 84, 4, 16, -1 },
	{ "Ground", 16, 108, 200, 8, 1 },
	{ "DampSand", 16, 116, 4, 20, 0 },
	{ "DampSand", 16, 140, 24, 4, 0 },
	{ "WetSand", 16, 144, 4, 24, -1 },
	{ "DampSand", 16, 168, 24, 4, 0 },
	{ "DampSand", 20, 80, 4, 24, 0 },
	{ "Ground", 20, 116, 24, 24, 1 },
	{ "WetSand", 20, 144, 16, 4, -1 },
	{ "Water", 20, 148, 12, 16, -2 },
	{ "WetSand", 20, 164, 16, 4, -1 },
	{ "Ground", 24, 76, 192, 32, 1 },
	{ "Ground", 32, 0, 8, 40, 1 },
	{ "DampSand", 32, 40, 4, 28, 0 },
	{ "Ground", 32, 68, 184, 8, 1 },
	{ "WetSand", 32, 148, 4, 16, -1 },
	{ "DampSand", 36, 40, 8, 4, 0 },
	{ "WetSand", 36, 44, 4, 20, -1 },
	{ "DampSand", 36, 64, 28, 4, 0 },
	{ "DampSand", 36, 144, 4, 24, 0 },
	{ "Ground", 40, 0, 176, 36, 1 },
	{ "DampSand", 40, 36, 24, 4, 0 },
	{ "WetSand", 40, 44, 8, 4, -1 },
	{ "Water", 40, 48, 16, 12, -2 },
	{ "WetSand", 40, 60, 20, 4, -1 },
	{ "Ground", 40, 140, 4, 32, 1 },
	{ "WetSand", 44, 40, 16, 4, -1 },
	{ "Ground", 44, 116, 8, 16, 1 },
	{ "DampSand", 44, 132, 4, 28, 0 },
	{ "Ground", 44, 160, 172, 12, 1 },
	{ "Water", 48, 44, 8, 4, -2 },
	{ "DampSand", 48, 132, 8, 4, 0 },
	{ "WetSand", 48, 136, 4, 20, -1 },
	{ "DampSand", 48, 156, 28, 4, 0 },
	{ "Ground", 52, 116, 164, 8, 1 },
	{ "DampSand", 52, 124, 4, 8, 0 },
	{ "WetSand", 52, 136, 8, 4, -1 },
	{ "Water", 52, 140, 12, 12, -2 },
	{ "WetSand", 52, 152, 20, 4, -1 },
	{ "WetSand", 56, 44, 4, 16, -1 },
	{ "DampSand", 56, 124, 24, 4, 0 },
	{ "WetSand", 56, 128, 4, 8, -1 },
	{ "DampSand", 60, 40, 4, 24, 0 },
	{ "WetSand", 60, 128, 16, 4, -1 },
	{ "Water", 60, 132, 12, 8, -2 },
	{ "Ground", 64, 36, 152, 32, 1 },
	{ "WetSand", 64, 140, 12, 4, -1 },
	{ "Water", 64, 144, 4, 8, -2 },
	{ "WetSand", 68, 144, 4, 8, -1 },
	{ "WetSand", 72, 132, 4, 8, -1 },
	{ "DampSand", 72, 144, 4, 12, 0 },
	{ "DampSand", 76, 128, 4, 20, 0 },
	{ "Ground", 76, 148, 140, 12, 1 },
	{ "Ground", 80, 124, 136, 24, 1 },
	{ "Ground", 172, 180, 44, 88, 1 },
	{ "DampSand", 172, 268, 4, 36, 0 },
	{ "Ground", 172, 304, 44, 16, 1 },
	{ "DampSand", 176, 268, 20, 4, 0 },
	{ "WetSand", 176, 272, 4, 28, -1 },
	{ "DampSand", 176, 300, 20, 4, 0 },
	{ "WetSand", 180, 272, 12, 4, -1 },
	{ "Water", 180, 276, 8, 20, -2 },
	{ "WetSand", 180, 296, 12, 4, -1 },
	{ "WetSand", 188, 276, 8, 4, -1 },
	{ "Water", 188, 280, 4, 12, -2 },
	{ "WetSand", 188, 292, 8, 4, -1 },
	{ "DampSand", 192, 272, 8, 4, 0 },
	{ "WetSand", 192, 280, 4, 12, -1 },
	{ "DampSand", 192, 296, 8, 4, 0 },
	{ "Ground", 196, 268, 20, 4, 1 },
	{ "DampSand", 196, 276, 4, 20, 0 },
	{ "Ground", 196, 300, 20, 4, 1 },
	{ "Ground", 200, 272, 16, 28, 1 },
}
-- { template, x, z, yaw, height scale }: each block's foot at CLIFF_FOOT
local CLIFFS = {
	{ "Cliff5", -227.5, 7.0, 270.0, 1.117 },
	{ "Cliff2", -227.6, 29.0, 270.0, 1.085 },
	{ "Cliff3", -244.0, 28.8, 265.9, 1.303 },
	{ "Cliff3", -226.3, 47.0, 270.0, 0.900 },
	{ "Cliff5", -227.9, 66.0, 270.0, 0.919 },
	{ "Cliff3", -227.4, 85.0, 270.0, 1.025 },
	{ "Cliff5", -243.0, 81.1, 264.9, 1.259 },
	{ "Cliff3", -226.9, 100.0, 270.0, 0.956 },
	{ "Cliff1", -226.2, 116.0, 270.0, 0.910 },
	{ "Cliff4", -244.0, 114.9, 269.4, 1.178 },
	{ "Cliff4", -229.4, 134.0, 270.0, 0.864 },
	{ "Cliff6", -227.2, 152.0, 270.0, 1.117 },
	{ "Cliff3", -244.0, 150.5, 269.2, 1.346 },
	{ "Cliff4", -228.8, 170.0, 270.0, 0.971 },
	{ "Cliff3", -226.9, 187.0, 270.0, 0.915 },
	{ "Cliff5", -243.0, 186.7, 264.2, 1.100 },
	{ "Cliff6", -227.6, 203.0, 270.0, 0.951 },
	{ "Cliff1", -227.1, 220.0, 270.0, 0.869 },
	{ "Cliff6", -243.0, 220.8, 272.5, 1.092 },
	{ "Cliff2", -227.2, 239.0, 270.0, 0.908 },
	{ "Cliff4", -246.0, 238.8, 277.5, 1.179 },
	{ "Cliff3", -226.5, 257.0, 270.0, 0.934 },
	{ "Cliff2", -227.4, 275.0, 270.0, 1.016 },
	{ "Cliff6", -245.0, 274.5, 276.2, 1.209 },
	{ "Cliff2", -228.4, 296.0, 270.0, 1.021 },
	{ "Cliff3", -227.0, 314.0, 270.0, 0.970 },
	{ "Cliff3", -242.0, 313.7, 276.8, 1.151 },
	{ "Cliff1", -226.8, 330.0, 270.0, 0.854 },
	{ "Cliff2", -210.0, 331.1, 360.0, 1.022 },
	{ "Cliff6", -191.0, 331.3, 360.0, 0.954 },
	{ "Cliff1", -174.0, 330.9, 360.0, 1.068 },
	{ "Cliff5", -154.0, 331.4, 360.0, 1.035 },
	{ "Cliff5", -131.0, 331.2, 360.0, 0.950 },
	{ "Cliff6", -134.4, 349.0, 352.3, 1.221 },
	{ "Cliff6", -111.0, 332.1, 360.0, 1.102 },
	{ "Cliff5", -108.8, 349.0, 353.0, 1.274 },
	{ "Cliff5", -91.0, 331.6, 360.0, 1.106 },
	{ "Cliff2", -69.0, 332.0, 360.0, 0.948 },
	{ "Cliff4", -68.9, 350.0, 365.0, 1.277 },
	{ "Cliff5", -47.0, 331.4, 360.0, 0.940 },
	{ "Cliff4", -26.0, 332.2, 360.0, 0.965 },
	{ "Cliff5", -22.0, 351.0, 357.3, 1.209 },
	{ "Cliff5", -5.0, 332.2, 360.0, 0.891 },
	{ "Cliff1", 15.0, 331.4, 360.0, 0.909 },
	{ "Cliff2", 16.6, 347.0, 353.2, 1.186 },
	{ "Cliff5", 35.0, 331.3, 360.0, 0.887 },
	{ "Cliff5", 58.0, 332.3, 360.0, 1.091 },
	{ "Cliff4", 79.0, 332.8, 360.0, 0.873 },
	{ "Cliff3", 78.5, 350.0, 367.1, 1.093 },
	{ "Cliff2", 99.0, 332.3, 360.0, 0.987 },
	{ "Cliff6", 118.0, 332.5, 360.0, 0.984 },
	{ "Cliff5", 138.0, 331.2, 360.0, 0.973 },
	{ "Cliff3", 157.0, 330.0, 360.0, 0.865 },
	{ "Cliff1", 173.0, 330.1, 360.0, 1.044 },
	{ "Cliff4", 174.5, 348.0, 365.0, 1.402 },
	{ "Cliff1", 190.0, 330.7, 360.0, 1.026 },
	{ "Cliff3", 206.0, 330.1, 360.0, 1.044 },
	{ "Cliff2", 207.2, 347.0, 359.0, 1.299 },
	{ "Cliff5", 225.0, 332.1, 360.0, 1.049 },
	{ "Cliff5", 227.4, 313.0, 90.0, 0.872 },
	{ "Cliff4", 228.7, 292.0, 90.0, 1.079 },
	{ "Cliff6", 227.2, 274.0, 90.0, 1.009 },
	{ "Cliff2", 227.3, 255.0, 90.0, 0.854 },
	{ "Cliff3", 244.0, 251.3, 88.9, 1.077 },
	{ "Cliff2", 227.8, 234.0, 90.0, 1.105 },
	{ "Cliff4", 246.0, 235.5, 94.1, 1.463 },
	{ "Cliff5", 228.3, 212.0, 90.0, 0.858 },
	{ "Cliff2", 227.5, 190.0, 90.0, 1.102 },
	{ "Cliff1", 244.0, 187.7, 94.7, 1.453 },
	{ "Cliff6", 227.3, 171.0, 90.0, 0.974 },
	{ "Cliff4", 246.0, 172.2, 90.6, 1.149 },
	{ "Cliff3", 227.3, 155.0, 90.0, 1.036 },
	{ "Cliff1", 242.0, 156.7, 82.8, 1.276 },
	{ "Cliff4", 229.1, 138.0, 90.0, 1.077 },
	{ "Cliff4", 228.9, 119.0, 90.0, 0.990 },
	{ "Cliff3", 246.0, 120.8, 87.8, 1.152 },
	{ "Cliff1", 226.6, 101.0, 90.0, 1.051 },
	{ "Cliff3", 227.4, 85.0, 90.0, 1.015 },
	{ "Cliff6", 228.2, 69.0, 90.0, 0.939 },
	{ "Cliff3", 226.2, 53.0, 90.0, 1.072 },
	{ "Cliff4", 244.0, 54.4, 87.9, 1.309 },
	{ "Cliff5", 227.1, 34.0, 90.0, 1.061 },
	{ "Cliff3", 244.0, 33.2, 88.8, 1.392 },
	{ "Cliff4", 228.4, 13.0, 90.0, 1.061 },
	{ "Cliff5", 247.0, 13.5, 93.7, 1.378 },
	{ "Cliff1", 227.0, -5.0, 90.0, 1.055 },
	{ "Cliff3", 213.0, -11.1, 180.0, 0.908 },
	{ "Cliff3", 198.0, -10.4, 180.0, 0.894 },
	{ "Cliff2", 180.0, -12.4, 180.0, 0.982 },
	{ "Cliff2", 178.9, -29.0, 177.8, 1.194 },
	{ "Cliff5", 158.0, -11.2, 180.0, 0.851 },
	{ "Cliff3", 139.0, -10.4, 180.0, 0.893 },
	{ "Cliff4", 122.0, -12.7, 180.0, 1.046 },
	{ "Cliff5", 101.0, -12.2, 180.0, 0.923 },
	{ "Cliff6", 102.9, -29.0, 174.0, 1.227 },
	{ "Cliff2", 79.0, -11.9, 180.0, 1.230 },
	{ "Cliff4", 79.7, -30.0, 180.3, 1.583 },
	{ "Cliff3", 61.0, -11.1, 180.0, 1.806 },
	{ "Cliff5", -71.0, -11.6, 180.0, 1.613 },
	{ "Cliff4", -92.0, -13.0, 180.0, 0.947 },
	{ "Cliff2", -95.0, -31.0, 180.3, 1.177 },
	{ "Cliff4", -111.0, -13.1, 180.0, 1.042 },
	{ "Cliff1", -129.0, -10.9, 180.0, 0.977 },
	{ "Cliff2", -148.0, -11.3, 180.0, 0.989 },
	{ "Cliff5", -170.0, -12.5, 180.0, 0.984 },
	{ "Cliff1", -190.0, -10.3, 180.0, 1.092 },
	{ "Cliff6", -192.1, -27.0, 187.6, 1.354 },
	{ "Cliff1", -207.0, -11.2, 180.0, 1.051 },
	{ "Cliff3", -209.1, -26.0, 179.8, 1.213 },
	{ "Cliff4", -225.0, -12.2, 180.0, 0.899 },
}
-- { template, x, y, z, yaw, scale }
local GREENS = {
	{ "Bush", -227.0, 20.7, 30.7, 257.8, 1.36 },
	{ "Bush", -228.3, 12.6, 65.9, 23.5, 0.90 },
	{ "Bush", -225.0, 10.4, 114.8, 266.7, 1.04 },
	{ "PalmTreeSmall", -243.0, 19.1, 186.7, 332.4, 1.50 },
	{ "Bush", -228.4, 19.4, 203.6, 172.0, 1.30 },
	{ "Bush", -229.7, 9.0, 217.8, 346.6, 0.97 },
	{ "Bush", -243.7, 25.3, 221.5, 281.6, 0.94 },
	{ "Bush", -228.3, 16.9, 257.6, 214.1, 1.03 },
	{ "Bush", -225.8, 18.1, 276.0, 288.1, 1.01 },
	{ "Bush", -231.4, 18.3, 294.1, 281.5, 1.17 },
	{ "PalmTreeSmall", -227.0, 18.3, 314.0, 213.3, 1.50 },
	{ "Bush", -225.4, 8.5, 327.1, 135.8, 0.93 },
	{ "Bush", -207.6, 18.3, 331.8, 284.7, 1.20 },
	{ "PalmTreeSmall", -191.0, 19.6, 331.3, 286.2, 1.50 },
	{ "PalmTreeSmall", -154.0, 16.8, 331.4, 200.4, 1.50 },
	{ "PalmTreeSmall", -131.0, 13.7, 331.2, 123.1, 1.50 },
	{ "Bush", -110.1, 25.8, 332.0, 269.4, 1.25 },
	{ "Bush", -107.1, 25.4, 351.4, 119.2, 1.27 },
	{ "Bush", -71.2, 15.5, 333.4, 301.9, 1.06 },
	{ "Bush", -67.3, 35.7, 350.1, 5.4, 1.00 },
	{ "Bush", -46.5, 13.3, 331.8, 186.1, 1.07 },
	{ "Bush", -26.0, 22.0, 332.6, 203.4, 1.26 },
	{ "Bush", 17.9, 10.4, 329.1, 343.0, 1.15 },
	{ "Bush", 18.7, 24.6, 347.7, 295.8, 1.08 },
	{ "PalmTreeSmall", 35.0, 11.4, 331.3, 233.6, 1.50 },
	{ "Bush", 59.6, 18.8, 330.3, 47.9, 1.03 },
	{ "Bush", 75.7, 23.2, 348.2, 202.9, 0.93 },
	{ "Bush", 97.3, 17.0, 333.5, 52.2, 1.09 },
	{ "Bush", 120.4, 20.8, 331.9, 49.0, 1.11 },
	{ "Bush", 138.4, 14.5, 329.0, 152.0, 1.23 },
	{ "Bush", 159.7, 14.1, 329.2, 314.3, 1.07 },
	{ "Bush", 174.2, 15.0, 330.3, 335.4, 1.34 },
	{ "Bush", 173.5, 41.2, 348.9, 285.4, 0.96 },
	{ "Bush", 203.9, 21.3, 328.6, 287.4, 1.03 },
	{ "Bush", 207.7, 28.8, 349.5, 112.8, 1.16 },
	{ "Bush", 227.7, 17.3, 334.3, 175.7, 1.39 },
	{ "Bush", 226.9, 10.9, 313.4, 277.2, 1.25 },
	{ "Bush", 231.3, 27.0, 294.9, 306.4, 1.13 },
	{ "Bush", 225.3, 11.9, 252.5, 288.6, 1.39 },
	{ "Bush", 245.3, 22.6, 249.9, 278.0, 0.98 },
	{ "PalmTreeSmall", 227.8, 21.5, 234.0, 285.0, 1.50 },
	{ "Bush", 242.0, 28.9, 189.6, 28.9, 1.27 },
	{ "Bush", 224.6, 20.4, 168.9, 191.8, 1.06 },
	{ "Bush", 244.9, 30.1, 174.0, 261.8, 1.13 },
	{ "Bush", 230.2, 20.9, 155.1, 242.9, 1.32 },
	{ "PalmTreeSmall", 242.0, 22.9, 156.7, 225.1, 1.50 },
	{ "Bush", 231.2, 26.9, 139.6, 161.4, 1.31 },
	{ "Bush", 228.0, 23.1, 120.0, 46.3, 1.36 },
	{ "Bush", 248.6, 25.6, 119.5, 320.9, 1.05 },
	{ "PalmTreeSmall", 227.4, 20.1, 85.0, 157.2, 1.50 },
	{ "PalmTreeSmall", 228.2, 18.9, 69.0, 358.3, 1.50 },
	{ "Bush", 242.5, 37.1, 57.0, 43.9, 0.94 },
	{ "Bush", 241.0, 35.2, 34.1, 36.7, 1.02 },
	{ "Bush", 226.9, 15.4, -7.7, 181.6, 1.00 },
	{ "PalmTreeSmall", 213.0, 15.8, -11.1, 37.8, 1.50 },
	{ "Bush", 200.2, 15.3, -11.4, 289.2, 1.23 },
	{ "Bush", 179.7, 16.8, -12.2, 172.6, 1.00 },
	{ "Bush", 180.4, 24.9, -28.5, 147.3, 1.13 },
	{ "Bush", 158.0, 10.1, -10.8, 324.6, 0.91 },
	{ "PalmTreeSmall", 139.0, 15.2, -10.4, 27.2, 1.50 },
	{ "Bush", 124.7, 25.5, -11.9, 182.4, 1.30 },
	{ "PalmTreeSmall", 101.0, 12.7, -12.2, 314.9, 1.50 },
	{ "Bush", 79.0, 49.2, -31.8, 252.6, 1.21 },
	{ "Bush", 58.9, 51.8, -11.0, 40.3, 1.28 },
	{ "Bush", -73.5, 37.6, -10.1, 91.4, 1.15 },
	{ "Bush", -96.7, 24.2, -30.6, 265.2, 1.33 },
	{ "Bush", -111.5, 25.3, -11.8, 37.0, 0.91 },
	{ "Bush", -145.9, 17.1, -9.3, 249.7, 1.39 },
	{ "Bush", -170.2, 14.9, -14.2, 64.2, 1.04 },
	{ "Bush", -191.9, 16.6, -10.1, 319.2, 1.15 },
	{ "Bush", -194.2, 36.4, -25.5, 119.1, 0.94 },
	{ "PalmTreeSmall", -225.0, 19.1, -12.2, 22.6, 1.50 },
}

local function find(name)
	for _, d in SS:GetDescendants() do
		if d.Name == name and d:IsA("Model") then
			return d
		end
	end
	error("no template " .. name .. " under ServerStorage")
end

-- floor
local templates, old = {}, {}
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and KINDS[p.Name] and p.Position.Z > 0 and not p:GetAttribute("World3Biome") then
		if not templates[p.Name] then
			templates[p.Name] = p:Clone()
		end
		table.insert(old, p)
	end
end
for name in KINDS do
	assert(templates[name], "no base " .. name .. " part to copy the look of")
end
for _, p in old do
	p:Destroy()
end
for _, r in FLOOR do
	local p = templates[r[1]]:Clone()
	local sx, sz, top = r[4], r[5], r[6]
	p.Size = Vector3.new(sx, top + 3, sz)
	p.CFrame = CFrame.new(r[2] + sx / 2, (top - 3) / 2, r[3] + sz / 2)
	p.Parent = W.Ground
end

-- the old walls: invisible barriers
for _, p in W.Walls:GetChildren() do
	if p.Name == "BaseWall" or p.Name == "BaseCap" then
		p.Transparency = 1
	end
end

-- cliffs, greens and the sea
local old_cove = W.BaseDecor:FindFirstChild("Cove")
if old_cove then
	old_cove:Destroy()
end
local cove = Instance.new("Folder")
cove.Name = "Cove"
cove.Parent = W.BaseDecor
local cache = {}
local function place(name, cf, sy, scale, collide)
	cache[name] = cache[name] or find(name)
	local m = cache[name]:Clone()
	local pivot = m:GetPivot()
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = collide
			p.CanQuery = collide
			if sy ~= 1 then -- (taller or shorter: the meshes unrotated in their template)
				local rel = pivot:ToObjectSpace(p.CFrame)
				p.Size = Vector3.new(p.Size.X, p.Size.Y * sy, p.Size.Z)
				p.CFrame = pivot * CFrame.new(rel.X, rel.Y * sy, rel.Z) * rel.Rotation
			end
		end
	end
	if scale ~= 1 then
		m:ScaleTo(scale)
	end
	m:PivotTo(cf)
	m.Parent = cove
end
for _, c in CLIFFS do
	place(c[1], CFrame.new(c[2], CLIFF_FOOT, c[3]) * CFrame.Angles(0, math.rad(c[4]), 0), c[5], 1, true)
end
for _, g in GREENS do
	place(g[1], CFrame.new(g[2], g[3], g[4]) * CFrame.Angles(0, math.rad(g[5]), 0), 1, g[6], false)
end
local water = templates.Water
for _, s in { { -1500, -246, -400, 1500 }, { 246, 1500, -400, 1500 }, { -246, 246, 350, 1500 } } do
	local p = water:Clone()
	p.Name = "Sea"
	p.Size = Vector3.new(s[2] - s[1], 2, s[4] - s[3])
	p.CFrame = CFrame.new((s[1] + s[2]) / 2, SEA_TOP - 1, (s[3] + s[4]) / 2)
	p.CanCollide = false
	p.Parent = cove
end
print("cove base:", #FLOOR, "floor parts,", #CLIFFS, "cliffs,", #GREENS, "greens")
