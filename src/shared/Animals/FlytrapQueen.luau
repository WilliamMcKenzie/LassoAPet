-- FlytrapQueen: World 3 Garden's boss as a trophy Legendary pet (Oct 14), like the Seraphs: 1 in
-- 1,000 of the Garden's stampede. Reuses the boss model (Bosses/FlytrapQueenModel). You ride on
-- the purple bulb, behind the stems.

local Horse = require(script.Parent.Horse)
local FlytrapQueenModel = require(script.Parent.Parent.Bosses.FlytrapQueenModel)

return Horse.variant("FlytrapQueen", FlytrapQueenModel, "Legendary", {
	seat = Vector3.new(0, 12.0, 3.0),
	neck = { center = Vector3.new(0, 13.8, 0.5), radius = 2.0 },
})
