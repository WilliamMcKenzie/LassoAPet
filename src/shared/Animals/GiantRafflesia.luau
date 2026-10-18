-- GiantRafflesia: World 3 Garden's boss as a trophy Legendary pet (Oct 15, replaces the Flytrap Queen),
-- like the Seraphs: 1 in 1,000 of the Garden's stampede. Reuses the boss model (Bosses/GiantRafflesiaModel).
-- You ride on the stem top, behind the flower.

local Horse = require(script.Parent.Horse)
local GiantRafflesiaModel = require(script.Parent.Parent.Bosses.GiantRafflesiaModel)

return Horse.variant("GiantRafflesia", GiantRafflesiaModel, "Legendary", {
	seat = Vector3.new(0, 34.0, 1.5),
	seatBone = "Stem",
	neck = { center = Vector3.new(0, 20.0, 0.0), radius = 2.6 },
})
