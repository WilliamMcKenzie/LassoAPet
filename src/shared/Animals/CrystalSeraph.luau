-- The Crystal Seraph as a pet (QM, Oct 13): World 2 Crystal Cavern's boss, the biblically accurate angel in
-- cyan and pink crystal, also runs in its biome's stampede about 1 in 300 (Config, World 2 block). A trophy:
-- it floats along slowly (Speed 0.5) but earns a lot of gold. You ride sitting on its halo,
-- clear of the spinning rings. The same model as the boss (Shared/Bosses/CrystalSeraphModel, from
-- tools/angel_boss.py), sized by its tier like any pet.

local Horse = require(script.Parent.Horse)
local CrystalSeraphModel = require(script.Parent.Parent.Bosses.CrystalSeraphModel)

return Horse.variant("CrystalSeraph", CrystalSeraphModel, "Legendary", {
	seat = Vector3.new(0, 34.4, 0), -- (on its halo)
	neck = { center = Vector3.new(0, 18.15, 0), radius = 4.6 }, -- (round its core)
})
