-- World 2's props (QM, Oct 13; draft). Made by tools/world2_props.py: edit that and
-- re-make this, not this. Run in Studio (Edit, execute_luau) on the place with World2,
-- after the floor scripts and world2_clear. Re-running is fine (it replaces its own).
-- Clusters of the Rock mesh thread's crimson set (Crimson Lands) and crystals and fungi
-- (Crystal Cavern) hugging the walls, the course's middle clear. Big and middle pieces
-- go in World2.Obstacles (smashed when ridden into: an invisible Base footprint and a
-- Tier, like World 1's); small ones in World2.Decor.Props, walk-through.
-- Each piece is cloned from ServerStorage.World2Assets.<Name>: a Model of its coloured
-- MeshParts at the mesh's own size, pivot at its base's middle.
local W = workspace.World2
local OFFSET = 1000
local SCALE = 2
local assets = game:GetService("ServerStorage"):WaitForChild("World2Assets", 5)
assert(assets, "ServerStorage.World2Assets (the imported crimson and crystal meshes) not found")
-- { biome, name, x, y (the tile's top), z, yaw, tier (0 = walk-through decor), base size x, base size z }
local PROPS = {
	{ "Crimson", "MushroomGiant", -57.0, 1, -2205.6, 229, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", -53.8, 1, -2220.1, 188, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", -46.4, 0, -2222.2, 291, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -50.2, 0, -2212.3, 238, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -40.6, 0, -2216.1, 196, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", -53.4, 1, -2198.8, 147, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", 57.6, 0, -2313.8, 117, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", 45.1, 2, -2299.5, 182, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", 46.3, 1, -2313.1, 212, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 55.0, 1, -2304.0, 221, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 54.0, 1, -2297.6, 61, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 47.5, 2, -2323.9, 15, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", 40.2, 1, -2318.4, 251, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 45.3, 2, -2329.5, 174, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", -58.1, 1, -2416.1, 224, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", -46.6, 1, -2431.4, 212, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", -51.3, 1, -2428.7, 250, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -57.9, 2, -2398.6, 106, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", -41.0, 1, -2428.3, 71, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", 58.1, 2, -2416.1, 33, 2, 9.6, 6.4 },
	{ "Crimson", "RuneBlock", 53.2, 2, -2401.5, 284, 1, 17.6, 9.2 },
	{ "Crimson", "CrimsonTuft", 51.9, 2, -2424.0, 165, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 41.8, 2, -2430.8, 243, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", 58.4, 0, -2489.9, 138, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", 56.8, 0, -2504.1, 58, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", 43.6, 1, -2506.2, 282, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 57.8, 0, -2498.3, 150, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 48.5, 0, -2488.3, 80, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 58.1, 1, -2476.2, 18, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", 48.6, 0, -2500.3, 116, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 42.6, 0, -2489.9, 184, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 45.9, 0, -2495.8, 331, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -58.9, 2, -2579.4, 286, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", -43.4, 2, -2572.4, 255, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", -48.3, 1, -2567.8, 26, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -51.8, 2, -2574.8, 359, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -53.4, 2, -2593.4, 315, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", 58.9, 2, -2579.4, 128, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", 48.0, 1, -2567.0, 241, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", 46.9, 1, -2594.9, 68, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 56.0, 2, -2565.6, 140, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 53.9, 2, -2575.6, 53, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", 59.3, 0, -2658.6, 61, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", 59.1, 1, -2644.1, 283, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", 51.1, 0, -2664.0, 106, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 55.9, 0, -2671.8, 355, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 52.0, 0, -2649.7, 57, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -59.3, 2, -2658.6, 201, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", -51.5, 2, -2670.8, 120, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", -57.1, 2, -2650.4, 349, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -48.2, 2, -2649.0, 139, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -49.5, 2, -2643.5, 152, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -43.8, 2, -2653.6, 156, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", -59.7, 0, -2735.6, 228, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", -52.7, 0, -2743.3, 360, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", -57.2, 0, -2748.4, 278, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -47.0, 1, -2730.2, 293, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -50.0, 0, -2753.3, 245, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -44.1, 0, -2752.6, 13, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", -47.2, 0, -2736.8, 124, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -56.3, 1, -2727.4, 2, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", 60.1, 1, -2821.0, 81, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", 48.6, 0, -2807.9, 228, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", 54.2, 1, -2833.8, 98, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 45.6, 1, -2827.5, 161, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 44.8, 0, -2837.4, 91, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 59.5, 1, -2828.4, 337, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", 42.4, 1, -2822.7, 343, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 46.4, 1, -2818.1, 31, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -60.1, 0, -2821.0, 7, 2, 9.6, 6.4 },
	{ "Crimson", "RuneBlock", -52.9, 0, -2829.8, 232, 1, 17.6, 9.2 },
	{ "Crimson", "CrimsonTuft", -46.2, 0, -2805.6, 64, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -54.6, 0, -2818.2, 191, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -44.1, 0, -2813.2, 69, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -60.6, 2, -2916.6, 32, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", -48.6, 2, -2925.1, 86, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", -47.4, 1, -2903.1, 255, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -55.2, 2, -2913.5, 284, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -51.0, 2, -2906.7, 262, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", 60.9, 1, -2986.4, 263, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", 49.8, 1, -2984.5, 178, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", 55.3, 2, -3001.8, 102, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 47.3, 0, -2969.3, 281, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 43.9, 1, -2983.3, 213, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 49.1, 1, -2990.1, 321, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", 47.2, 2, -3000.9, 110, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -61.3, 2, -3060.8, 97, 2, 9.6, 6.4 },
	{ "Crimson", "RuneBlock", -52.6, 1, -3050.0, 28, 1, 17.6, 9.2 },
	{ "Crimson", "CrimsonTuft", -54.2, 1, -3061.0, 202, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -61.0, 2, -3069.5, 202, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -57.3, 2, -3072.1, 138, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -51.3, 2, -3075.9, 358, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", 61.7, 0, -3140.5, 360, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", 54.7, 0, -3151.5, 180, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", 54.3, 0, -3124.8, 231, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 46.7, 0, -3133.4, 310, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 51.3, 0, -3144.2, 194, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", -62.0, 1, -3200.7, 186, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", -59.5, 2, -3190.6, 310, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", -52.0, 1, -3209.4, 217, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -48.8, 1, -3205.8, 355, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", -52.5, 2, -3186.7, 212, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -53.3, 1, -3215.6, 348, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -45.3, 2, -3202.4, 113, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", 62.4, 0, -3282.7, 131, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", 49.8, 0, -3288.0, 113, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", 55.9, 0, -3268.4, 236, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 55.5, 0, -3295.8, 64, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 60.1, 0, -3265.9, 338, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 59.8, 0, -3300.2, 47, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", 51.7, 1, -3274.2, 257, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 50.4, 0, -3268.8, 245, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", -62.9, 1, -3371.4, 163, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", -53.4, 2, -3364.0, 226, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", -50.4, 2, -3356.6, 345, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -56.6, 0, -3379.8, 310, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", -53.9, 1, -3374.6, 201, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", 62.9, 0, -3371.4, 93, 2, 9.6, 6.4 },
	{ "Crimson", "RuneBlock", 50.8, 0, -3383.2, 262, 1, 17.6, 9.2 },
	{ "Crimson", "CrimsonTuft", 49.8, 0, -3361.9, 80, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 53.1, 0, -3365.8, 354, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 62.8, 0, -3388.3, 69, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", 63.2, 1, -3434.7, 350, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", 48.5, 1, -3425.5, 54, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", 59.7, 2, -3421.9, 220, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 55.4, 1, -3427.0, 161, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 47.1, 1, -3446.3, 301, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", 61.4, 2, -3427.2, 287, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 52.6, 1, -3445.8, 143, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -63.2, 2, -3434.7, 242, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", -48.3, 1, -3439.7, 228, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", -49.5, 1, -3448.9, 343, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -53.7, 1, -3443.2, 187, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", -63.7, 0, -3540.3, 330, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", -57.4, 0, -3554.8, 289, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", -53.0, 1, -3542.6, 55, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -49.6, 1, -3531.2, 119, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -59.0, 1, -3528.5, 0, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", -48.3, 1, -3555.2, 106, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", -62.8, 1, -3531.3, 126, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", 63.7, 2, -3540.3, 186, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", 60.6, 2, -3531.9, 38, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", 50.3, 1, -3522.3, 103, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 47.0, 1, -3548.4, 71, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", 64.2, 0, -3649.6, 208, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", 52.8, 0, -3656.8, 18, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", 63.6, 0, -3634.4, 0, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 47.4, 0, -3659.5, 78, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 60.8, 0, -3666.1, 20, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", 53.8, 0, -3641.8, 285, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -64.6, 2, -3716.3, 104, 2, 9.6, 6.4 },
	{ "Crimson", "RuneBlock", -52.7, 1, -3700.8, 344, 1, 17.6, 9.2 },
	{ "Crimson", "CrimsonTuft", -61.6, 2, -3729.5, 190, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -50.7, 1, -3715.4, 261, 0, 5.6, 5.6 },
	{ "Crimson", "MushroomGiant", 64.6, 1, -3716.3, 29, 3, 12.0, 12.0 },
	{ "Crimson", "MushroomMedium", 51.0, 0, -3723.0, 145, 2, 8.0, 8.0 },
	{ "Crimson", "MushroomSmall", 51.2, 0, -3715.7, 31, 0, 4.0, 4.0 },
	{ "Crimson", "MushroomSmall", 60.4, 1, -3729.7, 45, 0, 4.0, 4.0 },
	{ "Crimson", "CrimsonTuft", 56.0, 1, -3732.2, 270, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", 65.0, 1, -3790.3, 134, 2, 9.6, 6.4 },
	{ "Crimson", "RuneBlock", 54.8, 1, -3804.6, 334, 1, 17.6, 9.2 },
	{ "Crimson", "CrimsonTuft", 57.5, 1, -3791.9, 7, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 57.5, 2, -3776.4, 228, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -65.0, 2, -3790.3, 174, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", -55.0, 1, -3776.2, 193, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", -48.4, 1, -3788.1, 223, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -57.9, 2, -3803.3, 115, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", -65.4, 2, -3883.0, 308, 2, 9.6, 6.4 },
	{ "Crimson", "RunestoneShort", -52.0, 1, -3883.7, 117, 1, 8.8, 6.4 },
	{ "Crimson", "CrimsonTuft", -51.7, 1, -3870.3, 301, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -57.9, 1, -3870.3, 307, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -58.2, 2, -3876.6, 170, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", -62.9, 2, -3897.3, 161, 0, 5.6, 5.6 },
	{ "Crimson", "RunestoneTall", 65.4, 2, -3883.0, 148, 2, 9.6, 6.4 },
	{ "Crimson", "RuneBlock", 58.5, 2, -3870.5, 189, 1, 17.6, 9.2 },
	{ "Crimson", "CrimsonTuft", 48.9, 1, -3896.0, 262, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 58.7, 2, -3894.3, 215, 0, 5.6, 5.6 },
	{ "Crimson", "CrimsonTuft", 49.3, 1, -3868.5, 342, 0, 5.6, 5.6 },
	{ "Cavern", "CrystalPinkXXL", 64.1, 2, -4028.8, 79, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalPinkMedium", 51.3, 1, -4011.1, 17, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalPinkMedium", 48.4, 1, -4040.6, 120, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", -66.5, 2, -4101.2, 292, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", -58.1, 1, -4102.8, 162, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", -63.0, 1, -4087.1, 72, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -53.0, 1, -4096.7, 314, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalPinkXXL", 64.9, 2, -4180.8, 337, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalPinkMedium", 62.2, 2, -4198.7, 303, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalPinkMedium", 50.7, 1, -4190.9, 59, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", -67.2, 2, -4248.1, 89, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", -63.2, 1, -4255.2, 133, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", -63.7, 1, -4239.7, 56, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -56.7, 1, -4260.3, 346, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -52.0, 1, -4251.6, 16, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalPinkXXL", 65.6, 2, -4323.4, 298, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalPinkMedium", 50.9, 1, -4333.9, 353, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", -68.1, 2, -4423.0, 67, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", -62.3, 2, -4409.7, 123, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", -54.2, 1, -4414.2, 70, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -54.4, 1, -4433.6, 100, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -64.5, 2, -4438.7, 83, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalCyanXXL", 66.6, 1, -4518.4, 125, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalCyanMedium", 59.3, 2, -4501.2, 357, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", -69.0, 2, -4591.4, 53, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", -62.4, 1, -4598.7, 217, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", -60.8, 1, -4607.2, 137, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -53.4, 1, -4586.3, 356, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalCyanXXL", 67.4, 2, -4674.6, 211, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalCyanMedium", 58.5, 1, -4691.2, 321, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", -69.8, 2, -4757.3, 180, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", -69.2, 2, -4748.9, 323, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", -59.8, 1, -4753.0, 80, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -61.4, 1, -4766.5, 168, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -60.6, 1, -4742.1, 353, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalPinkXXL", 67.8, 2, -4757.3, 100, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalPinkMedium", 52.8, 1, -4741.1, 179, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalPinkMedium", 59.5, 2, -4772.6, 174, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", 70.2, 2, -4836.9, 101, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", 60.7, 2, -4842.0, 323, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", 61.6, 1, -4850.1, 251, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", 68.4, 2, -4826.5, 296, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalPinkMedium", 59.0, 2, -4823.1, 263, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalCyanXXL", -68.6, 2, -4924.7, 105, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalCyanMedium", -57.1, 1, -4910.4, 355, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", 71.1, 2, -5021.4, 5, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", 63.2, 1, -5009.9, 141, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", 56.5, 1, -5037.1, 185, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", 61.1, 2, -5020.4, 355, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalPinkMedium", 68.7, 2, -5038.8, 67, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalPinkXXL", -69.1, 1, -5021.4, 298, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalPinkMedium", -54.6, 1, -5030.7, 16, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", -71.6, 2, -5119.4, 333, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", -69.2, 2, -5129.0, 234, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", -61.7, 2, -5108.5, 38, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -70.1, 2, -5104.5, 235, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalPinkMedium", -63.7, 1, -5134.3, 126, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalPinkXXL", 70.1, 2, -5212.0, 130, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalPinkMedium", 56.2, 2, -5196.3, 282, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalPinkMedium", 63.0, 1, -5229.3, 0, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", -72.4, 2, -5279.1, 275, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", -68.7, 2, -5267.2, 298, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", -68.4, 2, -5289.3, 12, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -57.2, 1, -5263.5, 114, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -57.3, 1, -5288.8, 154, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalCyanXXL", 70.9, 2, -5388.7, 109, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalCyanMedium", 55.5, 1, -5374.2, 154, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalCyanMedium", 59.7, 2, -5402.8, 144, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", -72.9, 2, -5388.7, 300, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", -68.9, 2, -5401.1, 11, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", -59.3, 1, -5378.3, 148, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", -61.2, 1, -5390.6, 82, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalCyanMedium", -56.4, 1, -5405.2, 13, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalPinkXXL", -71.4, 2, -5471.1, 215, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalPinkMedium", -60.3, 1, -5487.9, 43, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", 73.8, 2, -5567.5, 248, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", 64.6, 2, -5557.0, 120, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", 67.0, 1, -5582.7, 318, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", 58.4, 1, -5568.8, 204, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", 62.9, 1, -5575.7, 227, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalCyanXXL", -72.3, 2, -5655.8, 221, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalCyanMedium", -59.0, 1, -5670.5, 120, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalCyanMedium", -67.6, 1, -5638.1, 19, 0, 10.0, 10.0 },
	{ "Cavern", "FungusLarge", 74.6, 2, -5722.1, 82, 2, 12.0, 12.0 },
	{ "Cavern", "FungusMedium", 64.8, 2, -5717.1, 201, 1, 8.0, 8.0 },
	{ "Cavern", "FungusCluster", 63.3, 1, -5727.0, 89, 0, 10.0, 8.0 },
	{ "Cavern", "FungusCluster", 70.3, 2, -5735.3, 211, 0, 10.0, 8.0 },
	{ "Cavern", "CrystalPinkMedium", 65.2, 2, -5706.9, 170, 0, 10.0, 10.0 },
	{ "Cavern", "CrystalCyanXXL", -73.1, 2, -5820.7, 68, 3, 32.0, 32.0 },
	{ "Cavern", "CrystalCyanMedium", -61.5, 1, -5805.4, 311, 0, 10.0, 10.0 },
}

for _, m in W.Obstacles:GetChildren() do
	if m:GetAttribute("World2Prop") then
		m:Destroy()
	end
end
local decor = W.Decor:FindFirstChild("Props")
if decor then
	decor:Destroy()
end
decor = Instance.new("Folder")
decor.Name = "Props"
decor.Parent = W.Decor

local missing, placed = {}, 0
for _, r in PROPS do
	local template = assets:FindFirstChild(r[2])
	if not template then
		missing[r[2]] = true
		continue
	end
	local m = template:Clone()
	m:SetAttribute("World2Prop", r[1])
	m:ScaleTo(SCALE)
	m:PivotTo(CFrame.new(r[3] + OFFSET, r[4], r[5]) * CFrame.Angles(0, math.rad(r[6]), 0))
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = r[7] > 0
		end
	end
	if r[7] > 0 then
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Anchored, base.CanCollide, base.CanQuery, base.CanTouch = true, false, false, false
		base.Transparency = 1
		base.Size = Vector3.new(r[8], 1, r[9])
		base.CFrame = CFrame.new(r[3] + OFFSET, r[4] + 0.5, r[5]) * CFrame.Angles(0, math.rad(r[6]), 0)
		base.Parent = m
		m:SetAttribute("Tier", r[7])
		m.Parent = W.Obstacles
	else
		m.Parent = decor
	end
	placed += 1
end
local names = {}
for n in missing do
	table.insert(names, n)
end
return string.format("%d props placed%s", placed, if #names > 0 then " | missing in World2Assets: " .. table.concat(names, ", ") else "")
