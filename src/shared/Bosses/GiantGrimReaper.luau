-- The Giant Grim Reaper: the Halloween world's last boss, the Pumpkin Patch's (QM, Oct 15: "last one
-- grim reaper"). Soul Valley's Grim Reaper (Animals/GrimReaperModel, its meshes too), giant.

local Horse = require(script.Parent.Parent.Animals.Horse)
local GrimReaperModel = require(script.Parent.Parent.Animals.GrimReaperModel)

return Horse.variant("GiantGrimReaper", GrimReaperModel, "Legendary", {
	seat = Vector3.new(0, 7.2, 2), -- (the Grim Reaper's; no one rides the boss)
	neck = { center = Vector3.new(0, 8.6, -0.5), radius = 2.8 },
	size = 7, -- x the model: about 80 studs tall, the biggest of the three (a guess; Studio tunes it)
})
